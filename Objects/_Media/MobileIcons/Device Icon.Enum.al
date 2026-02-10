enum 81281 "MOB Device Icon"
{
    Caption = 'Mobile Device Icon', Locked = true;
    Access = Internal;
    Extensible = false;
    // Note: The name must be all lowercase even if image/icon id in application.cfg is camel case.
    //       The caption must be the resource path to the image file.
    //       When adding new icons, the enum ordinal (number) can be changed as the enums are not stored in the database.

    // Common (1-99)
    value(1; attachment)
    {
        Caption = 'icons/attachment.png', Locked = true;
    }
    value(2; calendar)
    {
        Caption = 'icons/calendar.png', Locked = true;
        // Not used in application.cfg
    }
    value(3; camera)
    {
        Caption = 'icons/camera.png', Locked = true;
    }
    value(4; document)
    {
        Caption = 'icons/document.png', Locked = true;
    }
    value(5; history)
    {
        Caption = 'icons/history.png', Locked = true;
    }
    value(6; imagecapture)
    {
        Caption = 'icons/imagecapture.png', Locked = true;
    }
    value(7; keyboard)
    {
        Caption = 'icons/keyboard.png', Locked = true;
        // Not used in application.cfg
    }
    value(8; mainmenuprint)
    {
        Caption = 'icons/mainmenuprint.png', Locked = true;
    }
    value(9; mainmenuquarantineorders)
    {
        Caption = 'icons/mainmenuquarantineorders.png', Locked = true;
    }
    value(10; mainmenureportasfinished)
    {
        Caption = 'icons/mainmenureportasfinished.png', Locked = true;
    }
    value(11; mainmenuscaninfo)
    {
        Caption = 'icons/mainmenuscaninfo.png', Locked = true;
    }
    value(12; mainmenuscaninfoi)
    {
        Caption = 'icons/mainmenuscaninfoi.png', Locked = true;
    }
    value(13; mainmenusettings)
    {
        Caption = 'icons/mainmenusettings.png', Locked = true;
    }
    value(14; post)
    {
        Caption = 'icons/paperplane.png', Locked = true;
    }
    value(15; reportasfinished)
    {
        Caption = 'icons/reportasfinished.png', Locked = true; // Image file used for mainmenupacking as well
    }
    value(16; trashcanempty)
    {
        Caption = 'icons/trashcanempty.png', Locked = true;
        // Not used in application.cfg
    }
    value(17; trashcanfilled)
    {
        Caption = 'icons/trashcanfilled.png', Locked = true;
    }
    value(18; uploadicon)
    {
        Caption = 'icons/uploadicon.png', Locked = true;
        // Not used in application.cfg
    }

    // ---------- Receive (100-149) ----------
    value(100; mainmenureceive)
    {
        Caption = 'icons/mainmenureceive.png', Locked = true;
    }

    // ---------- PutAway (150-199) ----------
    value(150; mainmenuputaway)
    {
        Caption = 'icons/mainmenuputaway.png', Locked = true;
    }

    // ---------- Move (200-249) ----------
    value(200; mainmenubulkmove)
    {
        Caption = 'icons/mainmenubulkmove.png', Locked = true;
    }
    value(201; mainmenumove)
    {
        Caption = 'icons/mainmenumove.png', Locked = true;
    }
    value(202; "mainmenumove-unplanned")
    {
        Caption = 'icons/mainmenumove-unplanned.png', Locked = true;
    }

    // ---------- Count (250-299) ----------
    value(250; mainmenucount)
    {
        Caption = 'icons/mainmenucount.png', Locked = true;
    }
    value(251; "mainmenucount-unplanned")
    {
        Caption = 'icons/mainmenucount-unplanned.png', Locked = true;
    }
    value(252; mainmenutagcountingjournallookup)
    {
        Caption = 'icons/mainmenutagcountingjournallookup.png', Locked = true;
    }

    // ---------- Pick (300-349) ----------
    value(300; mainmenupick)
    {
        Caption = 'icons/mainmenupick.png', Locked = true;
    }
    value(301; mainmenuboxpicking)
    {
        Caption = 'icons/mainmenuboxpicking.png', Locked = true;
    }

    // ---------- Packing (350-399) ----------
    value(350; mainmenupacking)
    {
        Caption = 'icons/reportasfinished.png', Locked = true; // Image file is placed in Common folder (used for reportasfinished as well)
    }

    // ---------- Shipping (400-449) ----------
    value(400; mainmenushipping)
    {
        Caption = 'icons/mainmenushipping.png', Locked = true;
    }
    value(401; "ship-unplanned")
    {
        Caption = 'icons/ship-unplanned.png', Locked = true;
        // Not used in application.cfg
    }
    value(402; shipcompleted)
    {
        Caption = 'icons/shipcompleted.png', Locked = true;
    }

    // ---------- Item Handling (450-499) ----------
    value(450; itemdimensions)
    {
        Caption = 'icons/itemdimensions.png', Locked = true;
    }
    value(451; mainmenubincontent)
    {
        Caption = 'icons/mainmenubincontent.png', Locked = true;
    }
    value(452; mainmenulocateitem)
    {
        Caption = 'icons/mainmenulocateitem.png', Locked = true;
    }
    value(453; mainmenunegativeadjustment)
    {
        Caption = 'icons/mainmenunegativeadjustment.png', Locked = true;
    }
    value(454; mainmenusubstituteitem)
    {
        Caption = 'icons/mainmenusubstituteitem.png', Locked = true;
    }

    // ---------- Assembly (500-549) ----------
    value(500; assembly)
    {
        Caption = 'icons/assembly.png', Locked = true;
    }
    value(501; mainmenuprofitlossjournallookup)
    {
        Caption = 'icons/mainmenuprofitlossjournallookup.png', Locked = true;
    }

    // ---------- Production (550-599) ----------
    value(550; mainmenuproduction)
    {
        Caption = 'icons/production.png', Locked = true;
    }
    value(551; productionconsumption)
    {
        Caption = 'icons/productionconsumption.png', Locked = true;
    }
    value(552; productionoutput)
    {
        Caption = 'icons/productionoutput.png', Locked = true;
    }
    value(553; produnplannedconsumption)
    {
        Caption = 'icons/productionconsumption-unplanned.png', Locked = true;
    }
    value(554; stopwatch)
    {
        Caption = 'icons/stopwatch.png', Locked = true;
    }

    // ---------- License Plate (600-649) ----------
    value(600; licenseplate)
    {
        Caption = 'icons/licenseplate.png', Locked = true;
    }
    value(601; mainmenuputawaylp)
    {
        Caption = 'icons/pallettruckwithlicenseplate.png', Locked = true;
    }
    value(602; mainmenucreatepallet)
    {
        Caption = 'icons/mainmenucreatepallet.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(603; mainmenupallettransport)
    {
        Caption = 'icons/mainmenupallettransport.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(604; "mainmenupallettransport-unplanned")
    {
        Caption = 'icons/mainmenupallettransport-unplanned.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }

    //  ---------- Other Icons - missing image file as resource (650-699) ----------
    value(650; locked)
    {
        Caption = 'locked.png', Locked = true;
    }
    value(651; menuplus)
    {
        Caption = 'plus.png', Locked = true;
    }
    value(652; menuminus)
    {
        Caption = 'minus.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(653; menuminusred)
    {
        Caption = 'minusred.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(654; minusred)
    {
        Caption = 'minusred.png', Locked = true;
        // Used as icon, but not declared as <image> in application.cfg
    }
    value(655; plus)
    {
        Caption = 'plus.png', Locked = true;
        // Used as icon, but not declared as <image> in application.cfg
    }
    value(656; registrationactiontypeplace)
    {
        Caption = 'registrationactiontypeplace.png', Locked = true;
    }
    value(657; registrationactiontypetake)
    {
        Caption = 'registrationactiontypetake.png', Locked = true;
    }
    value(658; registrationmenuitem)
    {
        Caption = 'registrationmenuitem.png', Locked = true;
        // Used as icon, but not declared as <image> in application.cfg
    }
    value(659; error)
    {
        Caption = 'error.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(661; mainmenuadjustqty)
    {
        Caption = 'mainmenuadjust.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(662; mainmenudefault)
    {
        Caption = 'mainmenudefault.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(663; postsuccess)
    {
        Caption = 'readytosendok.png', Locked = true;
    }
    value(664; posterror)
    {
        Caption = 'progresserror.png', Locked = true;
    }
    value(665; postready)
    {
        Caption = 'readytosend.png', Locked = true;
    }
    value(666; postinprogress)
    {
        Caption = 'registrationbegun.png', Locked = true;
    }
    value(667; registrationbegun)
    {
        Caption = 'registrationbegun.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(668; registrationcompleted)
    {
        Caption = 'registrationcompleted.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(669; registrationempty)
    {
        Caption = 'registrationempty.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(670; registrationmorethanhalfway)
    {
        Caption = 'registrationhalfwayplus.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
    value(671; transparent)
    {
        Caption = 'transparent.png', Locked = true;
        // Declared as <image>, but not used in application.cfg
    }
}
