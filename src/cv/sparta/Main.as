import com.google.analytics.AnalyticsTracker;
import com.google.analytics.GATracker;

import cv.managers.UpdateManager;
import cv.sparta.AboutWindow;
import cv.sparta.UpdateWindow;
import cv.sparta.components.HTMLToolTip;

import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import flash.desktop.ClipboardTransferMode;
import flash.desktop.NativeApplication;
import flash.desktop.NativeDragActions;
import flash.desktop.NativeDragManager;
import flash.events.Event;
import flash.events.NativeDragEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.FileFilter;

import mx.collections.ArrayCollection;
import mx.containers.FormItem;
import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.events.ValidationResultEvent;
import mx.managers.ToolTipManager;
import mx.validators.Validator;

[Bindable]
public var languagesList:ArrayCollection = new ArrayCollection([
	{label:"American English", data:"en_US"},
	{label:"British English", data:"en_GB"},
	{label:"Danish", data:"da_DK"},
	{label:"Dutch", data:"nl_NL"},
	{label:"Finish", data:"fi_FI"},
	{label:"French", data:"fr_FR"},
	{label:"German", data:"de_DE"},
	{label:"Italian", data:"it_IT"},
	{label:"Norwegian", data:"nb_NO"},
	{label:"Portugese", data:"pt_BR"},
	{label:"Spanish", data:"es_ES"},
	{label:"Catalan", data:"ca_ES"},
	{label:"Swedish", data:"sv_SE"},
	{label:"Ukranian", data:"uk_UK"},
	{label:"Chinese", data:"zh_CN"},
	{label:"Taiwanese", data:"zh_TW"},
	{label:"Japanese", data:"ja_JP"},
	{label:"Korean", data:"ko_KR"}
]);

[Bindable]
public var defTokensList:ArrayCollection = new ArrayCollection([
	{label:"Dreamweaver installation folder", data:"$Dreamweaver"},
	{label:"Fireworks installation folder", data:"$Fireworks"},
	{label:"Flash installation folder", data:"$Flash"},
	{label:"System or System32 folder", data:"$System"},
	{label:"Font folder on the computer’s hard disk", data:"$Fonts"},
	{label:"Folder that stores extension-specific file (2.x)", data:"$ExtensionSpecificEMStore"},
	{label:"Photoshop installation folder", data:"$photoshopappfolder"},
	{label:"Photoshop top level of the Plug-ins folder", data:"$pluginsfolder"},
	{label:"Photoshop top level of Presets folder", data:"$presetsfolder"},
	{label:"Photoshop Scripts folder", data:"$scripts"},
	{label:"Photoshop Actions folder", data:"$actions"},
	{label:"Photoshop Brushes folder", data:"$brushes"},
	{label:"Photoshop MATLAB folder", data:"$matlab"},
	{label:"Bridge installation folder", data:"$bridgeappfolder"},
	{label:"Bridge Plug-ins folder", data:"$pluginsfolder"},
	{label:"Bridge Presets folder", data:"$presetsfolder"},
	{label:"Bridge ExtensionManager Config folder", data:"$bridge"},
	{label:"Global (suite) startup scripts folder", data:"$startupscripts"},
	{label:"Bridge global startup scripts folder", data:"$bridgestartupscripts"},
	{label:"Bridge namespace extensions folder", data:"$extensions"},
	{label:"Bridge user workspaces folder", data:"$workspaces"},
	{label:"Bridge namespace extensions workspaces folder", data:"$extensionworkspaces"},
	{label:"Bridge user startup scripts folder", data:"$userscripts"},
	{label:"Illustrator installation folder", data:"$illustrator"},
	{label:"Illustrator Plug-ins folder", data:"$plugin"},
	{label:"Illustrator Scripting folder", data:"$scripting"},
	{label:"Illustrator Presets folder", data:"$presets"}
]);

[Bindable]
public var hasFile:Boolean = false;

[Bindable]
private var arrValidator:Array;

private var tracker:AnalyticsTracker;
private var aboutWin:AboutWindow;
private var updateWin:UpdateWindow;
private var um:UpdateManager;
private var fOpen:File = File.desktopDirectory;
private var app:NativeApplication = NativeApplication.nativeApplication;
private var mxiFilter:FileFilter = new FileFilter("MXI", "*.mxi;*.xml");
private var fSave:File = File.desktopDirectory.resolvePath("untitled.mxi");

// Note: Format should be written in Dreamweaver, Format isn't handled well

private function init(event:FlexEvent):void {
	ToolTipManager.toolTipClass = cv.sparta.components.HTMLToolTip;
	
	fOpen.addEventListener(Event.SELECT, onSelection);
	
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, dragHandler);
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, dragHandler);
	
	arrValidator = new Array();
	arrValidator.push(frmExtension.valName);
	arrValidator.push(frmExtension.valVersion);
	arrValidator.push(frmAuthor.valAuthor);
	
	// Init Updater
	um = UpdateManager.instance;
	um.addEventListener(UpdateManager.AVAILABLE, updateHandler);
	um.updateURL = "http://www.coursevector.com/projects/sparta/update.xml";
	um.checkNow();
	
	reset();
}

private function initTracker():void {
	// Analytics
	tracker = new GATracker(this, "UA-349755-7", "AS3", false);
	tracker.trackPageview("/sparta/" + UpdateManager.instance.currentVersion + "/MainScreen");
}

private function dragHandler(e:NativeDragEvent):void {
	var cb:Clipboard = e.clipboard;
	switch(e.type) {
		case NativeDragEvent.NATIVE_DRAG_ENTER :
			if(cb.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)){
				NativeDragManager.dropAction = NativeDragActions.LINK;
				NativeDragManager.acceptDragDrop(this);
			} else {
				tracker.trackEvent(".sparta-" + UpdateManager.instance.currentVersion, "error", "FileFormat1", -1);
				//trace("Unrecognized format");
			}
			break;
		case NativeDragEvent.NATIVE_DRAG_DROP :
			if(cb.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)){
				var arrFiles:Array = cb.getData(ClipboardFormats.FILE_LIST_FORMAT, ClipboardTransferMode.ORIGINAL_ONLY) as Array;
				fOpen = arrFiles[0];
				openFile(fOpen);
			} else {
				tracker.trackEvent(".sparta-" + UpdateManager.instance.currentVersion, "error", "FileFormat2", -1);
				//Alert.show(e.toString(), "Unrecognized File Format...", Alert.OK);
			}
			break;
	}
}

private function updateHandler(e:Event):void {
	switch(e.type) {
		case UpdateManager.AVAILABLE :
			updateWin = new UpdateWindow();
			updateWin.open();
			break;
	}
}

private function fileClose():void {
	reset();
	container.visible = false;
	hasFile = false;
	this.title = ".sparta";
}

private function fileSave():void {
	// Validate
	var arrValidatorError:Array = Validator.validateAll(arrValidator);
	var errorMessageArray:Array = [];
    var isValidForm:Boolean = arrValidatorError.length == 0;
    if (!isValidForm) {
        var err:ValidationResultEvent;
        for each (err in arrValidatorError) {
            var errField:String = FormItem(err.currentTarget.source.parent).label
            errorMessageArray.push(errField + " : " + err.message);
        }
    }
    
    if(ArrayCollection(frmProducts.destlist.dataProvider).length <= 0) {
    	errorMessageArray.push("Products : Please select atleast one target product.");
    }
    
    if(frmFiles.acItems.length <= 0) {
    	errorMessageArray.push("Files : Please add atleast one file.");
    }
    if(errorMessageArray.length > 0) {
		tracker.trackEvent(".sparta-" + UpdateManager.instance.currentVersion, "error", "MXI", -1);
    	Alert.show(errorMessageArray.join("\n\n"), "Invalid MXI...", Alert.OK);
    	return;
    }
	
	// Actually save
	if(fOpen.isDirectory) {
		fileSaveAs();
	} else {
		save();
	}
}

private function fileSaveAs():void {
	fSave.browseForSave("Save As");
}

private function onClickAbout():void {
	aboutWin = new AboutWindow();
    aboutWin.open();
}

private function fileOpen():void {
	fOpen.browseForOpen("Select File", [mxiFilter]);
}

private function fileNew():void {
	reset();
	container.visible = true;
	hasFile = true;
	
	if(fSave.hasEventListener(Event.SELECT)) fSave.removeEventListener(Event.SELECT, onSave);
	fSave = File.desktopDirectory.resolvePath("untitled.mxi");
	fSave.addEventListener(Event.SELECT, onSave, false, 0, true);
}

private function onSave(event:Event):void {
	var f:File = event.target as File;
	
	// Force MXI extension
	if (f.extension == null || f.extension.toLowerCase() != "mxi") {
		f.url += ".mxi";
	}
	
	var str:String;
	try {
		str = getMXI();
	} catch (e:Error) {
		tracker.trackEvent(".sparta-" + UpdateManager.instance.currentVersion, "error", "Save1", -1);
		Alert.show(e.message, 'Error Saving...', Alert.OK);
		return;
	}
	
	this.title = ".sparta - " + f.name;
	var stream:FileStream = new FileStream();
	stream.openAsync(f, FileMode.WRITE);
	stream.writeUTFBytes(str);
	stream.close();
}

private function save():void {
	var str:String;
	try {
		str = getMXI();
	} catch (e:Error) {
		tracker.trackEvent(".sparta-" + UpdateManager.instance.currentVersion, "error", "Save2", -1);
		Alert.show(e.message, 'Error Saving...', Alert.OK);
		return;
	}
	
	this.title = ".sparta - " + fOpen.name;
	var stream:FileStream = new FileStream();
	stream.openAsync(fOpen, FileMode.WRITE);
	stream.writeUTFBytes(str);
	stream.close();
}

private function onSelection(event:Event):void {
	openFile(event.target as File);
}

private function openFile(f:File):void {
	// Update fileWrite
	if(fSave.hasEventListener(Event.SELECT)) fSave.removeEventListener(Event.SELECT, onSave);
	fSave = new File(f.url);
	fSave.addEventListener(Event.SELECT, onSave, false, 0, true);
	
	var fs:FileStream = new FileStream();
	fs.addEventListener(Event.COMPLETE, onFileOpen);
	fs.openAsync(f, FileMode.READ);
	reset();
	hasFile = true;
	this.title = ".sparta - " + f.name;
}

private function onFileOpen(event:Event):void {
	
	var fs:FileStream = event.target as FileStream;
	var str:String = fs.readUTFBytes(fs.bytesAvailable);
	// Resid doesn't have a declared namespace
	var regexNS:RegExp = new RegExp('resid:', "gim");
	str = str.replace(regexNS, "resid_");
	
	try {
		setMXI(new XML(str));
	} catch (e:Error) {
		tracker.trackEvent(".sparta-" + UpdateManager.instance.currentVersion, "error", "Open", -1);
		Alert.show(e.toString(), "Error Opening...", Alert.OK);
		fileClose();
		return;
	}
	container.visible = true;
}

private function onTokenUpdate(event:Event):void {
	frmFiles.setCustomTokens(frmTokens.acItems);
}

private function reset():void {
	frmExtension.reset();
	frmLanguage.reset();
	frmAuthor.reset();
	frmDescription.reset();
	frmUpdate.reset();
	frmProducts.reset();
	frmLicense.reset();
	frmUIAccess.reset();
	frmFiles.reset();
	frmToolPanel.reset();
	frmConfig.reset();
	frmTokens.reset();
}

private function getMXI():String {
	var str:String = frmExtension.getXML();
	str += frmLanguage.getXML();
	str += frmAuthor.getXML();
	str += frmDescription.getXML();
	str += frmUpdate.getXML();
	str += frmProducts.getXML();
	str += frmLicense.getXML();
	str += frmUIAccess.getXML();
	str += frmFiles.getXML();
	str += "<configuration-changes>";
	str += frmToolPanel.getXML();
	str += frmConfig.getXML();
	str += "</configuration-changes>";
	str += frmTokens.getXML();
	str += "</macromedia-extension>";
	
	var xml:XML = new XML(str);
	var regexNS:RegExp = new RegExp(' xmlns="http://www.w3.org/XML/1998/namespace"', "gim");
	var regexNS2:RegExp = new RegExp(' xmlns:resid="http://ns.adobe.com/mxi"', "gim");
	var regexXML:RegExp = new RegExp(' lang="', "gim");
	str = xml.toXMLString();
	str = str.replace(regexNS, "");
	str = str.replace(regexNS2, "");
	str = str.replace(regexXML, ' xml:lang="');
	
	return str;
}

private function setMXI(x:XML):void {
	frmExtension.setXML(x);
	frmLanguage.setXML(x);
	frmAuthor.setXML(x);
	frmProducts.setXML(x);
	frmDescription.setXML(x);
	frmUpdate.setXML(x);
	frmUIAccess.setXML(x);
	frmLicense.setXML(x);
	frmFiles.setXML(x);
	frmToolPanel.setXML(x);
	frmConfig.setXML(x);
	frmTokens.setXML(x);
}