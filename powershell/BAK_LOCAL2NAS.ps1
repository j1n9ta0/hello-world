$DirArray = "D:\EasyDrv7", "D:\HUAWEI", "D:\ISO", "D:\VMware", "D:\WIM", "D:\下载", "D:\软件" 

$NAS_IP = "192.168.3.254"
$NAS_USER = "user"
$NAS_PASS = "Yunjie.888"
$NAS_PATH = "storage"

Start-Process -FilePath "cmdkey" -ArgumentList "/delete:$NAS_IP"
Start-Process -FilePath "cmdkey" -ArgumentList "/add:$NAS_IP /user:$NAS_USER /pass:$NAS_PASS"

foreach ($LocalDir in $DirArray) {

    $NAS_DIR = $LocalDir.Split('\')[-1]
    Start-Process  -FilePath "robocopy" -ArgumentList "$LocalDir \\$NAS_IP\$NAS_PATH\$NAS_DIR /MIR"  -Wait

}


# robocopy %%i "\\192.168.3.254\storage\%%b" /MIR