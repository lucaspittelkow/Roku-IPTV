sub init()
    m.top.backgroundURI = "pkg:/images/background-controls.jpg"

    m.save_feed_url = m.top.FindNode("save_feed_url")  'Save url to registry

    m.get_channel_list = m.top.FindNode("get_channel_list") 'get url from registry and parse the feed
    m.get_channel_list.ObserveField("content", "SetContent") 'Is thre content parsed? If so, goto SetContent sub and dsipay list

    m.list = m.top.FindNode("list")
    m.list.ObserveField("itemSelected", "setChannel") 

    m.video = m.top.FindNode("Video")
    m.video.ObserveField("state", "checkState")

    m.current_channel_label = m.top.FindNode("current_channel_label")
    m.current_channel_icon = m.top.FindNode("current_channel_icon")

    reg = CreateObject("roRegistrySection", "profile")
    if reg.Exists("primaryfeed") then
        m.get_channel_list.control = "RUN"
    else
        showdialog()  'Force a keyboard dialog.  
    end if

End sub

' **************************************************************

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    
    if(press) '
        if(key = "right")
            m.list.SetFocus(false)
            m.top.SetFocus(true)
            m.video.translation = [0, 0]
            m.video.width = 0
            m.video.height = 0
            result = true
        else if(key = "left")
            m.list.SetFocus(true)
            m.video.translation = [860, 100]
            m.video.width = 960
            m.video.height = 540
            result = true
        else if(key = "back")
            m.list.SetFocus(true)
            m.video.translation = [860, 100]
            m.video.width = 960
            m.video.height = 540
            result = true
        else if(key = "options")
            showdialog()
            result = true
        end if
    end if
    
    return result 
end function


sub checkState()
    state = m.video.state
    if(state = "error")
        m.top.dialog = CreateObject("roSGNode", "Dialog")
        m.top.dialog.title = "Erro: " + str(m.video.errorCode)
        m.top.dialog.message = m.video.errorMsg
    end if
end sub

sub SetContent()    
    m.list.content = m.get_channel_list.content
    m.list.SetFocus(true)
end sub

sub setChannel()
	if m.list.content.getChild(0).getChild(0) = invalid
		content = m.list.content.getChild(m.list.itemSelected)
	else
		itemSelected = m.list.itemSelected
		for i = 0 to m.list.currFocusSection - 1
			itemSelected = itemSelected - m.list.content.getChild(i).getChildCount()
		end for
		content = m.list.content.getChild(m.list.currFocusSection).getChild(itemSelected)
	end if

	'Probably would be good to make content = content.clone(true) but for now it works like this
	content.streamFormat = "hls, mp4, mkv, mp3, avi, ts, flv"

	if m.video.content <> invalid and m.video.content.url = content.url return

	content.HttpSendClientCertificates = true
	content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
	m.video.EnableCookies()
	m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
	m.video.InitClientCertificates()

    m.video.content = content
    m.current_channel_icon.uri   = content.HDGRIDPOSTERURL
    m.current_channel_label.text = content.shortdescriptionline1

	m.top.backgroundURI = "pkg:/images/rsgde_bg_hd.jpg"
	m.video.trickplaybarvisibilityauto = false

	m.video.control = "play"
end sub


sub showdialog()
    PRINT ">>>  ENTERING KEYBOARD <<<"

    keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboarddialog.title = "Digite a URL da lista de canais"

    keyboarddialog.buttons=["OK","Fechar"]
    keyboarddialog.optionsDialog=true

    m.top.dialog = keyboarddialog
    m.top.dialog.text = m.global.feedurl
    m.top.dialog.keyboard.textEditBox.cursorPosition = len(m.global.feedurl)
    m.top.dialog.keyboard.textEditBox.maxTextLength = 300
    m.top.dialog.focusButton = 0

    KeyboardDialog.observeFieldScoped("buttonSelected","onKeyPress")  'we observe button ok/cancel, if so goto to onKeyPress sub
end sub


sub onKeyPress()
    if m.top.dialog.buttonSelected = 0 ' OK
        m.global.feedurl = m.top.dialog.text
        m.save_feed_url.control = "RUN"
        m.get_channel_list.control = "RUN"
        m.top.dialog.close = true
    else if m.top.dialog.buttonSelected = 1 ' Fechar
        m.top.dialog.close = true
    end if
end sub
