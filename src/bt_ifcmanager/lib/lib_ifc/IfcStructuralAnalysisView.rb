#  IfcStructuralAnalysisView export from 3Skeng structural model
#
#  Copyright 2018 Jan Froehlich <jan.froehlich@shk.de>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.

require_relative File.join('Ifc_Type.rb')
require_relative File.join('IfcReal.rb')
require_relative File.join('IfcLabel.rb')
require_relative File.join('set.rb')
require_relative File.join('step_writer.rb')

require_relative File.join('IFC2X3', 'IfcOwnerHistory.rb')
require_relative File.join('IFC2X3', 'IfcPersonAndOrganization.rb')
require_relative File.join('IFC2X3', 'IfcPerson.rb')
require_relative File.join('IFC2X3', 'IfcOrganization.rb')
require_relative File.join('IFC2X3', 'IfcApplication.rb')

require_relative File.join('IFC2X3', 'IfcProject.rb')
require_relative File.join('IFC2X3', 'IfcGeometricRepresentationContext.rb')
require_relative File.join('IFC2X3', 'IfcAxis2Placement3D.rb')
require_relative File.join('IFC2X3', 'IfcLocalPlacement.rb')
require_relative File.join('IFC2X3', 'IfcCartesianPoint.rb')
require_relative File.join('IFC2X3', 'IfcDirection.rb')
require_relative File.join('IFC2X3', 'IfcSIUnit.rb')
require_relative File.join('IFC2X3', 'IfcUnitAssignment.rb')

require_relative File.join('IFC2X3', 'IfcSite.rb')
require_relative File.join('IFC2X3', 'IfcBuilding.rb')
require_relative File.join('IFC2X3', 'IfcBuildingStorey.rb')
require_relative File.join('IFC2X3', 'IfcRelAggregates.rb')

require_relative File.join('IFC2X3', 'IfcMaterial.rb')
require_relative File.join('IFC2X3', 'IfcDirection.rb')
require_relative File.join('IFC2X3', 'IfcAxis2Placement2D.rb')
require_relative File.join('IFC2X3', 'IfcParameterizedProfileDef.rb')
require_relative File.join('IFC2X3', 'IfcIShapeProfileDef.rb')
require_relative File.join('IFC2X3', 'IfcStructuralProfileProperties.rb')
require_relative File.join('IFC2X3', 'IfcBoundaryNodeCondition.rb')

require_relative File.join('IFC2X3', 'IfcLocalPlacement.rb')
require_relative File.join('IFC2X3', 'IfcVector.rb')
require_relative File.join('IFC2X3', 'IfcVertexPoint.rb')
require_relative File.join('IFC2X3', 'IfcLine.rb')
require_relative File.join('IFC2X3', 'IfcEdgeCurve.rb')
require_relative File.join('IFC2X3', 'IfcTopologyRepresentation.rb')
require_relative File.join('IFC2X3', 'IfcProductDefinitionShape.rb')
require_relative File.join('IFC2X3', 'IfcStructuralPointConnection.rb')
require_relative File.join('IFC2X3', 'IfcStructuralCurveConnection.rb')
require_relative File.join('IFC2X3', 'IfcStructuralCurveMember.rb')
require_relative File.join('IFC2X3', 'IfcRelAssociatesMaterial.rb')
require_relative File.join('IFC2X3', 'IfcRelAssociatesProfileProperties.rb')
require_relative File.join('IFC2X3', 'IfcRelConnectsStructuralMember.rb')
require_relative File.join('IFC2X3', 'IfcStructuralAnalysisModel.rb')
require_relative File.join('IFC2X3', 'IfcRelAssignsToGroup.rb')
require_relative File.join('IFC2X3', 'IfcRelServicesBuildings.rb')

module BimTools
 module IfcStructuralAnalysisView
  class Model
    
    attr_accessor :owner_history, :representationcontext
    attr_reader :structure, :project, :ifBIMc_objects
    
    # creates an IFC model based on given fem structure
    def initialize(structure)
      
      @structure = structure
      @ifc_id = 0
      
      
      # create empty array that will contain all IFC objects
      @ifc_objects = Array.new
      
      # create IfcOwnerHistory for all IFC objects
      @owner_history = create_ownerhistory()
      
      # create new IfcProject
      @project = create_project()
      
      # create IfcGeometricRepresentationContext for all IFC geometry objects
      @representationcontext = create_representationcontext()
      
      @project.representationcontexts = BimTools::IfcManager::Ifc_Set.new([@representationcontext])
      @project.ownerhistory = @owner_history
      
      # create project structure and hierarchy
      @buildingstorey = create_projectstructure()
      
      # lookup table for ifc_ids of ifc_objects referred to structure objects
      @lut = Hash.new { |hash, key| hash[key] = [] }
      
      # create material, releases and sections
      @material = create_material()
      create_releases(structure)
      create_sections(structure)
      
      # create IFC objects for all structure instances
      
      create_ifc_objects(structure)
    end
    
    # add object to ifc_objects array
    def add( ifc_object )
      @ifc_objects << ifc_object
      return new_id()
    end
    
    def new_id()
      @ifc_id += 1
    end
    
    def export( file_path )
      BimTools::IfcManager::IfcStepWriter.new( self, 'file_schema', 'file_description', file_path, @su_model )
      
    end
    
    
    # create new IfcProject
    def create_project()
      m = BimTools::IFC2X3::IfcSIUnit.new(self)
      m.dimensions = '*'
      m.unittype = '.LENGTHUNIT.'
      m.name = '.METRE.'
      unitsincontext = BimTools::IFC2X3::IfcUnitAssignment.new(self)
      unitsincontext.units = BimTools::IfcManager::Ifc_Set.new([m])
      project = BimTools::IFC2X3::IfcProject.new(self)
      project.name = BimTools::IfcManager::IfcLabel.new('Default Project')
      project.description = BimTools::IfcManager::IfcLabel.new('Description of Default Project')
      project.unitsincontext = unitsincontext
      return project
    end 
    
    # Create new IfcOwnerHistory
    def create_ownerhistory()
      owner_history = BimTools::IFC2X3::IfcOwnerHistory.new( self )
      owner_history.owninguser = BimTools::IFC2X3::IfcPersonAndOrganization.new( self )
      owner_history.owninguser.theperson = BimTools::IFC2X3::IfcPerson.new( self )
      owner_history.owninguser.theperson.familyname = BimTools::IfcManager::IfcLabel.new('')
      owner_history.owninguser.theorganization = BimTools::IFC2X3::IfcOrganization.new( self )
      owner_history.owninguser.theorganization.name = BimTools::IfcManager::IfcLabel.new('3skeng')
      owner_history.owningapplication = BimTools::IFC2X3::IfcApplication.new( self )
      owner_history.owningapplication.applicationdeveloper = owner_history.owninguser.theorganization
      owner_history.owningapplication.version = BimTools::IfcManager::IfcLabel.new('0.1')
      owner_history.owningapplication.applicationfullname = BimTools::IfcManager::IfcLabel.new('3Skeng Ifc Exporter')
      owner_history.owningapplication.applicationidentifier = BimTools::IfcManager::IfcLabel.new('su_3S_Ifc')
      owner_history.changeaction = '.ADDED.'
      owner_history.creationdate = Time.now.to_i.to_s
      return owner_history
    end 
    
    # Create new IfcGeometricRepresentationContext
    def create_representationcontext()
      representationcontext = BimTools::IFC2X3::IfcGeometricRepresentationContext.new( self )
      representationcontext.contexttype = BimTools::IfcManager::IfcLabel.new('Model')
      representationcontext.coordinatespacedimension = '3'
      representationcontext.worldcoordinatesystem = BimTools::IFC2X3::IfcAxis2Placement3D.new( self )
      representationcontext.worldcoordinatesystem.location = BimTools::IFC2X3::IfcCartesianPoint.new( self )
      representationcontext.worldcoordinatesystem.location.coordinates = '(0., 0., 0.)'
      representationcontext.truenorth = create_direction([0, 1, 0])
      return representationcontext
    end 
    
	# Create new Project Structure
    def create_projectstructure()
      site = BimTools::IFC2X3::IfcSite.new(self)
      site.ownerhistory = @owner_history
      site.name = BimTools::IfcManager::IfcLabel.new('Default Site')
      site.compositiontype = '.ELEMENT.'
      building = BimTools::IFC2X3::IfcBuilding.new(self)
      building.ownerhistory = @owner_history
      building.name = BimTools::IfcManager::IfcLabel.new('Default Building')
      building.compositiontype = '.ELEMENT.'
      buildingstorey = BimTools::IFC2X3::IfcBuildingStorey.new(self)
      buildingstorey.name = BimTools::IfcManager::IfcLabel.new('Default Building Storey')
      buildingstorey.compositiontype = '.ELEMENT.'
      #project structure hierarchy
      aggregation = BimTools::IFC2X3::IfcRelAggregates.new(self)
      aggregation.ownerhistory = @owner_history
      aggregation.name = BimTools::IfcManager::IfcLabel.new('ProjectContainer')
      aggregation.relatingobject = @project
      aggregation.relatedobjects = BimTools::IfcManager::Ifc_Set.new([site])
      aggregation = BimTools::IFC2X3::IfcRelAggregates.new(self)
      aggregation.ownerhistory = @owner_history
      aggregation.name = BimTools::IfcManager::IfcLabel.new('SiteContainer')
      aggregation.relatingobject = site
      aggregation.relatedobjects = BimTools::IfcManager::Ifc_Set.new([building])
      aggregation = BimTools::IFC2X3::IfcRelAggregates.new(self)
      aggregation.ownerhistory = @owner_history
      aggregation.name = BimTools::IfcManager::IfcLabel.new('BuildingContainer')
      aggregation.relatingobject = building
      aggregation.relatedobjects = BimTools::IfcManager::Ifc_Set.new([buildingstorey])
      return buildingstorey
    end
    
    # create IFC objects for all structure instances
    def create_ifc_objects(structure)
      ifc_set = []
      
      #create ifc objects for nodes
      structure.nodes.each do |node|
        ifc_set << create_node(node)
      end
      
      #create ifc objects for beams
      structure.beams.each do |beam|
        ifc_set << create_member(beam)
      end
      
      #create strucutral view
      structuralview = BimTools::IFC2X3::IfcStructuralAnalysisModel.new(self)
      structuralview.ownerhistory = @owner_history
      structuralview.name = BimTools::IfcManager::IfcLabel.new('3Skeng Analytical Model')
      structuralview.predefinedtype = '.LOADING_3D.'
      structuralview.orientationof2dplane = @representationcontext.worldcoordinatesystem
      groupassignment = BimTools::IFC2X3::IfcRelAssignsToGroup.new(self)
      groupassignment.ownerhistory = @owner_history
      groupassignment.relatedobjects = BimTools::IfcManager::Ifc_Set.new(ifc_set)
      groupassignment.relatinggroup = structuralview
      buildingassignment = BimTools::IFC2X3::IfcRelServicesBuildings.new(self)
      buildingassignment.ownerhistory = @owner_history
      buildingassignment.relatingsystem = structuralview
      buildingassignment.relatedbuildings = BimTools::IfcManager::Ifc_Set.new([@buildingstorey])
      
    end
    
    def create_localplacement(ifc_object, origin = [0, 0, 0])
      location = create_cartesianpoint(origin)
      axis = create_direction([0, 0, 1])
      refdirection = create_direction([1, 0, 0])
      coordinatesystem = BimTools::IFC2X3::IfcAxis2Placement3D.new(self)
      coordinatesystem.location = location
      coordinatesystem.axis = axis
      coordinatesystem.refdirection = refdirection
      localplacement = BimTools::IFC2X3::IfcLocalPlacement.new(self)
      localplacement.relativeplacement = coordinatesystem
      localplacement.placementrelto = ifc_object
      return localplacement
    end
    
    def create_direction(ratios)
      direction = BimTools::IFC2X3::IfcDirection.new(self)
      direction.directionratios = BimTools::IfcManager::Ifc_Set.new()
      ratios.each do |ratio|
        direction.directionratios.add(BimTools::IfcManager::IfcReal.new(ratio).step)
      end
      return direction
    end
    
    def create_cartesianpoint(coordinates)
      cp = BimTools::IFC2X3::IfcCartesianPoint.new(self)
      cp.coordinates = BimTools::IfcManager::Ifc_Set.new()
      coordinates.each do |coordinate|
        cp.coordinates.add(BimTools::IfcManager::IfcReal.new(coordinate).step)
      end
      return cp
    end
    
    def create_material()
      material = BimTools::IFC2X3::IfcMaterial.new(self)
      material.name = BimTools::IfcManager::IfcLabel.new('S235')
      return material
    end
    
    def create_sections(structure)
      structure.sections.each do |section|
        profiledef = create_profiledef(section)
        @lut[section.id].push(profiledef)
      end
    end
    
    def create_profiledef(section)
      # create 2D origin
      cartesianpoint = create_cartesianpoint([0, 0])
      direction = create_direction([1, 0])
      placement = BimTools::IFC2X3::IfcAxis2Placement2D.new(self)
      placement.location = cartesianpoint
      placement.refdirection = direction      
      # define profile
      profile = BimTools::IFC2X3::IfcParameterizedProfileDef.new(self)
      profile.profiletype = '.AREA.'
      name = section.id.gsub('-','')
      name.gsub!('x','X')
      profile.profilename = "'#{name}'"
      profile.position = placement
      # define profile
#      profile = BimTools::IFC2X3::IfcIShapeProfileDef.new(self)
#      profile.profiletype = '.AREA.'
#      name = section.id.gsub('-','')
#      name.gsub!('x','X')
#      profile.profilename = "'#{name}'"
#      profile.position = placement
#      profile.overallwidth = section.b.inch.to_m.round(5).to_s
#      profile.overalldepth = section.h.inch.to_m.round(5).to_s
#      profile.flangethickness = section.tf.to_m.round(5).to_s
#      profile.webthickness = section.tw.inch.to_m.round(5).to_s
      profileproperties = BimTools::IFC2X3::IfcStructuralProfileProperties.new(self)
      profileproperties.profilename = BimTools::IfcManager::IfcLabel.new(name)
      profileproperties.profiledefinition = profile
      
      return profileproperties
    end
    
    def create_releases(structure)
      structure.releases.each do |release|
        boundarycondition = create_boundarycondition(release)
        @lut[release.to_s].push(boundarycondition)
      end
    end
    
    def create_boundarycondition(release)
      boundarycondition = BimTools::IFC2X3::IfcBoundaryNodeCondition.new(self)
      boundarycondition.name = BimTools::IfcManager::IfcLabel.new('Member release')
      dof = release.map {|dof| (dof.nil?) ? -1:0}
      boundarycondition.linearstiffnessx = BimTools::IfcManager::IfcReal.new(dof[0])
      boundarycondition.linearstiffnessy = BimTools::IfcManager::IfcReal.new(dof[1])
      boundarycondition.linearstiffnessz = BimTools::IfcManager::IfcReal.new(dof[2])
      boundarycondition.rotationalstiffnessx = BimTools::IfcManager::IfcReal.new(dof[3])
      boundarycondition.rotationalstiffnessy = BimTools::IfcManager::IfcReal.new(dof[4])
      boundarycondition.rotationalstiffnessz = BimTools::IfcManager::IfcReal.new(dof[5])
      return boundarycondition
    end
    
    def create_node(node)
      #1: equivalent to tranformation in global coordinate system 
      localplacement = BimTools::IFC2X3::IfcLocalPlacement.new(self)
      localplacement.relativeplacement = @representationcontext.worldcoordinatesystem
      #2: coordinates
      cartesianpoint = create_cartesianpoint(node.in_unit('m'))
      @lut[node].push(cartesianpoint)
      #3: create vertex 
      vertexpoint = BimTools::IFC2X3::IfcVertexPoint.new(self)
      vertexpoint.vertexgeometry = cartesianpoint
      @lut[node].push(vertexpoint)
      #4: define representation 
      topologyrepresentation = BimTools::IFC2X3::IfcTopologyRepresentation.new(self)
      topologyrepresentation.contextofitems = @representationcontext
      topologyrepresentation.representationtype = BimTools::IfcManager::IfcLabel.new('Vertex')
      topologyrepresentation.items = BimTools::IfcManager::Ifc_Set.new([vertexpoint])
      #5: define shape 
      productdefinitionshape = BimTools::IFC2X3::IfcProductDefinitionShape.new(self)
      productdefinitionshape.representations = BimTools::IfcManager::Ifc_Set.new([topologyrepresentation])
      #6: define structural meaningful node 
      structuralpointconnection = BimTools::IFC2X3::IfcStructuralPointConnection.new(self)
      structuralpointconnection.ownerhistory = @owner_history
      structuralpointconnection.name = BimTools::IfcManager::IfcLabel.new("3s Node #{node.id}")
      structuralpointconnection.description = BimTools::IfcManager::IfcLabel.new('')
      structuralpointconnection.objectplacement = localplacement
      structuralpointconnection.representation = productdefinitionshape
      @lut[node].push(structuralpointconnection)
      return structuralpointconnection
    end
    
    def create_member(beam)
      #1: equivalent to tranformation in global coordinate system 
      localplacement = BimTools::IFC2X3::IfcLocalPlacement.new(self)
      localplacement.relativeplacement = @representationcontext.worldcoordinatesystem
      #2: create line
      direction = create_direction(beam.xdirection.to_a)
      vector = BimTools::IFC2X3::IfcVector.new(self)
      vector.orientation = direction
      vector.magnitude = beam.length('m').to_s
      line = BimTools::IFC2X3::IfcLine.new(self)
      line.pnt = @lut[beam.nodes[0]][0]
      line.dir = vector
      #2: node link of edge      
      edgecurve = BimTools::IFC2X3::IfcEdgeCurve.new(self)
      edgecurve.edgestart = @lut[beam.nodes[0]][1]
      edgecurve.edgeend = @lut[beam.nodes[-1]][1]
      edgecurve.edgegeometry = line
      edgecurve.samesense = '.T.'
      #4: define representation 
      topologyrepresentation = BimTools::IFC2X3::IfcTopologyRepresentation.new(self)
      topologyrepresentation.contextofitems = @representationcontext
      topologyrepresentation.representationtype = BimTools::IfcManager::IfcLabel.new('Edge')
      topologyrepresentation.items = BimTools::IfcManager::Ifc_Set.new([edgecurve])
      #5: define shape 
      productdefinitionshape = BimTools::IFC2X3::IfcProductDefinitionShape.new(self)
      productdefinitionshape.representations = BimTools::IfcManager::Ifc_Set.new([topologyrepresentation])
      #6: define structural meaningful line
#      structuralcurveconnection = BimTools::IFC2X3::IfcStructuralCurveConnection.new(self)
#      structuralcurveconnection.ownerhistory = @owner_history
#      structuralcurveconnection.name = "'3s Edge #{beam.id}'" 
#      structuralcurveconnection.description = "''"
#      structuralcurveconnection.objectplacement = localplacement
#      structuralcurveconnection.representation = productdefinitionshape
      #6: define structural meaningful member
      structuralcurvemember = BimTools::IFC2X3::IfcStructuralCurveMember.new(self)
      structuralcurvemember.ownerhistory = @owner_history
      structuralcurvemember.name = BimTools::IfcManager::IfcLabel.new("3s Member #{beam.id}") 
      structuralcurvemember.description = BimTools::IfcManager::IfcLabel.new('')
      structuralcurvemember.objectplacement = localplacement
      structuralcurvemember.representation = productdefinitionshape      
      structuralcurvemember.predefinedtype = '.RIGID_JOINED_MEMBER.'
      #7: association to material
      amaterial = BimTools::IFC2X3::IfcRelAssociatesMaterial.new(self)
      amaterial.ownerhistory = @owner_history
      amaterial.relatedobjects = BimTools::IfcManager::Ifc_Set.new([structuralcurvemember])
      amaterial.relatingmaterial = @material
      #8: association to section
      asection = BimTools::IFC2X3::IfcRelAssociatesProfileProperties.new(self)
      asection.relatedobjects = BimTools::IfcManager::Ifc_Set.new([structuralcurvemember])
      asection.relatingprofileproperties = @lut[beam.section.id][0]
      orientation = create_direction(beam.zdirection.to_a)
      asection.profileorientation = orientation
      #9: association to releases
      arelease = BimTools::IFC2X3::IfcRelConnectsStructuralMember.new(self)
      arelease.ownerhistory = @owner_history
      arelease.name = BimTools::IfcManager::IfcLabel.new('Start node')
      arelease.relatingstructuralmember = structuralcurvemember
      arelease.relatedstructuralconnection = @lut[beam.nodes[0]][2]
      arelease.appliedcondition = @lut[beam.releases[0].dof.to_s][0]
      arelease = BimTools::IFC2X3::IfcRelConnectsStructuralMember.new(self)
      arelease.ownerhistory = @owner_history
      arelease.name = BimTools::IfcManager::IfcLabel.new('End node')
      arelease.relatingstructuralmember = structuralcurvemember
      arelease.relatedstructuralconnection = @lut[beam.nodes[-1]][2]
      arelease.appliedcondition = @lut[beam.releases[-1].dof.to_s][0]
      return structuralcurvemember
    end
  end
 end
end

