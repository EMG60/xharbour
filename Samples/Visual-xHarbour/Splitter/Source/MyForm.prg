GLOBAL AppCaption

#include "vxh.ch"
#include "MyForm.xfm"

#translate xCRLF => CHR(13) + CHR(10)
//---------------------------------------- End of system code ----------------------------------------//

//-- CONFIRM QUIT ------------------------------------------------------------------------------------//
METHOD MyForm_OnClose( Sender ) CLASS MyForm
   IF ::Messagebox( "Exit this Visual xHarbour sample?", AppCaption + " | Exit", MB_YESNO + MB_ICONQUESTION) <> 6
      RETURN .F.
   END
RETURN Self

//-- GENERAL LINK ------------------------------------------------------------------------------------//
METHOD LinkWebsite_OnClick( Sender ) CLASS MyForm
   ShellExecute(::hWnd, "OPEN", Sender:Url, , , SW_SHOW)
RETURN Self

//-- QUICK MENU --------------------------------------------------------------------------------------//
METHOD QMenu_About_OnClick( Sender ) CLASS MyForm
   ::MessageBox( "This Visual xHarbour sample project was created by xHarbour.com Inc." + xCRLF + xCRLF + "The user is free to change the source code of this sample project to his/her own desire." , AppCaption + " | About", MB_OK + MB_ICONASTERISK)
RETURN Self

METHOD QMenu_MainSite_OnClick( Sender ) CLASS MyForm
   ShellExecute(::hWnd, "OPEN", "http://www.xHarbour.com/", , , SW_SHOW)
RETURN Self

METHOD QMenu_ShopSite_OnClick( Sender ) CLASS MyForm
   ShellExecute(::hWnd, "OPEN", "http://www.xHarbour.com/Order/", , , SW_SHOW)
RETURN Self

METHOD QMenu_Exit_OnClick( Sender ) CLASS MyForm
   ::Close()
RETURN Self   
//-- INITIALISE SAMPLE -------------------------------------------------------------------------------//
METHOD MyForm_OnLoad( Sender ) CLASS MyForm   
   LOCAL MyRoot, aSubDirs, i

   // SAMPLE DETAILS
   AppCaption := ::Application:Name + " " + ::Application:Version

   ::LinkWebsite:Caption := "http://www.xHarbour.com/TrainingCenter/"
   ::LinkWebsite:Url := "http://www.xharbour.com/trainingcenter/"

   ::Caption := "xHarbour.com Training Center | " + AppCaption

   WITH OBJECT ::MyTreeView
      MyRoot := :AddItem("Project Root Folder")   

      aSubDirs := Directory(CurDrive() + ":\" + CurDir() + "\", "D")
      FOR i := 1 TO Len(aSubDirs)
         IF aSubDirs[i][1] != "." .AND. aSubDirs[i][1] != ".." .AND. aSubDirs[i][5] == "D"
            MyRoot:AddItem(aSubDirs[i][1])
         END
      NEXT

      MyRoot:AddItem("This is a dummy directory with a very long name")
      :ExpandAll()
   END
RETURN Self