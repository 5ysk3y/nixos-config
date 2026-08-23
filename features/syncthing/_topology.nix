{
  devices = {
    gibson = {
      id = "7VDI5S5-BHDGS6M-HOD26MV-DYVHJ7Z-WJQ3RKA-NI5UWP7-BRXWYKF-DLJYAQ4";
      addresses = [ "dynamic" ];
      autoAcceptFolders = false;
      introducer = false;
    };

    syncMaster = {
      id = "NFYVMXE-T3IVMTV-UMLRBZ3-RQ246DT-QV3CCRG-45W5D23-EYFQFNY-Z6AH7QH";
      addresses = [ "tcp://192.168.1.165:22000" ];
      autoAcceptFolders = true;
      introducer = false;
    };

    macbook = {
      id = "G4QTXBM-ZNDISJJ-L6D3NQG-EDKOJLA-YOOFPSG-PRGCXZV-3RVVZWH-2I3XDAE";
      addresses = [ "dynamic" ];
      autoAcceptFolders = false;
      introducer = false;
    };
  };

  folders = {
    sync = {
      id = "sync";
      label = "Sync";
    };
  };
}
