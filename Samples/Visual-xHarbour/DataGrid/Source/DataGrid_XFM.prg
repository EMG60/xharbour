#include "vxh.ch"
//---------------------------------------- End of system code ----------------------------------------//

//------------------------------------------------------------------------------------------------------------------------------------

CLASS __DataGrid INHERIT Application
   // Components declaration
   METHOD Init() CONSTRUCTOR

   // Event declaration
ENDCLASS

METHOD Init( oParent, aParameters ) CLASS __DataGrid
   ::Super:Init( oParent, aParameters )


   // Populate Components
   // Properties declaration
   ::Version              := "2.1.0.0"
   ::Resources            := {  }

   ::Create()

   // Populate Children
RETURN Self

