<?PHP
#########################################################
#                                                       #
# CA Config Editor copyright 2017-2019, Andrew Zawadzki #
#                                                       #
#########################################################

$plugin = "nvidia-vgpu-driver";
$docroot = $docroot ?: $_SERVER['DOCUMENT_ROOT'] ?: '/usr/local/emhttp';
$translations = file_exists("$docroot/webGui/include/Translations.php");
if ($translations) {
	// add translations
	$_SERVER['REQUEST_URI'] = 'configedit';
	require_once "$docroot/webGui/include/Translations.php";
} else {
	// legacy support (without javascript)
	$noscript = true;
	require_once "$docroot/plugins/$plugin/include/Legacy.php";
}

function readCFGfile($filename) {
  $data['contents'] = @file_get_contents($filename);
  if ($data['contents'] === false) {
    $data['error'] = "true";
  }
  $data['format'] = (strpos($data['contents'],"\r\n")) ? "dos" : "linux";
  $data['contents'] = str_replace("\r","",$data['contents']);
  return $data;
}

switch ($_POST['action']) {
  case 'edit':
    $filename = urldecode($_POST['filename']);
    echo json_encode(readCFGfile($filename));
    break;
  case 'save':
    $filedata = $_POST['filedata'];
    $backupContents = file_get_contents($filedata['filename']);
    file_put_contents("{$filedata['filename']}.bak",$backupContents);
    if ( $filedata['format'] == "true" ) {
      $filedata['contents'] = str_replace("\n","\r\n",$filedata['contents']);
    }
    file_put_contents($filedata['filename'],$filedata['contents']);
    echo "ok";
    break;
  case 'getBackup':
    $filename = urldecode($_POST['filename']);
    if (is_file("$filename.bak") ) {
      echo file_get_contents("$filename.bak");
    } else {
      echo _("No Backup File Found");
    }
    break;
}
?>
