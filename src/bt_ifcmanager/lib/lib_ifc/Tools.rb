# ==3skeng Tool Ifc Export
#
#  ©2018 by SHK Engineering and Consulting GmbH & Co KG
#  SHK CONFIDENTIAL - VERTRAULICH
#  Software Author:	Jan Froehlich
#  Design:			Sebastian Kummer

# Exporting Ifc views



module BimTools
  module Tools
    def self.export_system_lines()
      Sketchup.active_model.start_operation("export system lines",true)
      
      file_path = UI.savepanel("Selction to Ifc Structural Analysis View", Sketchup.active_model.path, "AnalyticalModel.ifc")
      
      unless file_path
        Sketchup.active_model.abort_operation
        return
      end
      
      Sketchup.status_text = "Selection to Ifc Structural Analysis View...0/3"
      
      #get Steelwork elements in Selection and creates structure from them
      structure = Tsk3_Fem::Structure.new(Sketchup.active_model.selection)
      
      if !structure.valid
        Sketchup.active_model.abort_operation
        UI.messagebox('Erroneous structure')
      end
      
       Sketchup.status_text = "Created valid analytical model...1/3"
      
      ifcmodel = BimTools::IfcStructuralAnalysisView::Model.new(structure)
      
     Sketchup.status_text = "Created ifc model...2/3"
      
      ifcmodel.export(file_path)
      
      Sketchup.status_text = "Successfully exported ifc model...3/3"
    end
  end
end