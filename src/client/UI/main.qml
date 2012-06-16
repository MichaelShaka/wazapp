/***************************************************************************
**
** Copyright (c) 2012, Tarek Galal <tarek@wazapp.im>
**
** This file is part of Wazapp, an IM application for Meego Harmattan
** platform that allows communication with Whatsapp users.
**
** Wazapp is free software: you can redistribute it and/or modify it under
** the terms of the GNU General Public License as published by the
** Free Software Foundation, either version 2 of the License, or
** (at your option) any later version.
**
** Wazapp is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
** See the GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with Wazapp. If not, see http://www.gnu.org/licenses/.
**
****************************************************************************/
import QtQuick 1.1
import com.nokia.meego 1.0
//import com.nokia.extras 1.0

WAStackWindow {
    id: appWindow
    initialPage: mainPage
    
	//Temporary variables for settings testing
	property int myOrientation: 0
	property int bubbleColor: 1

	signal goToEndOfList
	signal setFocusToChatText
	signal sendCurrentMessage
	signal addEmojiToChat
	property string addedEmojiCode
	property bool showSendButton
	signal updateUnreadCount
	property string activeWindow
	property bool addToUread: false

    property string waversiontype:waversion.split('.').length == 4?'developer':'beta'
    
    showStatusBar: !(screen.currentOrientation == Screen.Landscape && activeConvJId!="")
    toolBarPlatformStyle:ToolBarStyle{
        inverted: stealth || theme.inverted
    }
    property string activeConvJId:""
    property bool stealth:false
	property string emojiDialogParent

    Component.onCompleted: {
        //theme.inverted = true
    }

    platformStyle: defaultStyle

    onStealthMode: {
        console.log("Stealth Mode!")
        theme.inverted = false
        stealth = true;
       // theme.inverted = true
        platformStyle = stealthStyle
    }
    onNormalMode: {
        console.log("Normal Mode!")
        stealth = false
         //theme.inverted = false
        platformStyle=defaultStyle
    }



    function isStealth(){
        return stealth;
    }

    PageStackWindowStyle { id: defaultStyle }
    PageStackWindowStyle {
           id: stealthStyle;
         //  backgroundColor: "black"
       }



    /*InfoBanner {
        id:osd_notify
       // iconSource: "system_banner_thumbnail.png"
    }*/



    /****** Signal and Slot definitions *******/

    signal changeStatus(string new_status)
    signal sendMessage(string user_id, string msg);
    signal sendRegRequest(string number, string cc);
    signal requestPresence(string user_id);
    signal refreshContacts();
    signal sendTyping(string user_id);
    signal sendPaused(string user_id);
    signal stealthMode()
    signal normalMode()
    signal quit()
    signal deleteConversation(string cid);
	signal deleteSingleMessage(string user_id, int msg_id);
    signal conversationActive(string user_id);
    signal fetchMedia(int id);
    signal fetchGroupMedia(int id);
    signal loadConversationsThread(string user_id, int first, int limit);


            /******************/
    function onConnected(){setIndicatorState("online")}
    function onConnecting(){setIndicatorState("connecting")}
    function onDisconnected(){setIndicatorState("connecting")}
    function onSleeping(){setIndicatorState("offline")}
    function onLoginFailed(){setIndicatorState("reregister")}

            /**** Media ****/
    function onMediaTransferSuccess(jid,message_id,mediaObject){
        console.log("Caught media transfer success in main")
        waContacts.onMediaTransferSuccess(jid,message_id,mediaObject);
    }

    function onMediaTransferError(jid,message_id,mediaObject){
        console.log("ERROR!! "+jid)
        waContacts.onMediaTransferError(jid,message_id,mediaObject);
    }

    function onMediaTransferProgressUpdated(progress,jid,message_id){
        console.log("UPDATED PROGRESS "+progress)

         waContacts.onMediaTransferProgressUpdated(progress,jid,message_id);
    }




    function appFocusChanged(focus){

        var user_id = getActiveConversation()
        if (user_id){

            conversationActive(user_id);
        }

    }

    function setActiveConv(activeJid){
        console.log("SETTING ACTIVE CONV "+activeJid)
        activeConvJId=activeJid
    }

    function onUpdateAvailable(updateData){
        updateDialog.version = updateData.l
        updateDialog.link = updateData.d
        updateDialog.severity = updateData.u
        updateDialog.changes = updateData.m

        updatePage.version = updateData.l
        updatePage.url = updateData.d
        updatePage.urgency = updateData.u
        updatePage.summary = updateData.m

        var changes = ""
        for(var i =0; i<updateData.c.length; i++){
            changes += "* "+updateData.c[i]+"\n";

        }

        updatePage.changes = changes

        updateDialog.open()

        waMenu.updateVisible = true;
    }

    function quitInit(){
        quitConfirm.open();
    }

    function showNotification(text,fixed) {

        if(fixed)
            osd_notify.timerEnabled=false

        osd_notify.topMargin=100

        osd_notify.text=text
        osd_notify.show();
    }

	function updatingConversationsOn() {
		addToUread = false
	}

	function updatingConversationsOff() {
		addToUread = true
	}

	//prevent double opened, sometimes QContactsManager sends more than 1 signal
	property bool updateContactsOpenend: false

	function onContactsChanged() {
		if (updateContactsOpenend==false) {
		console.log("CONTACTS CHANGED!!!");
			updateContactsOpenend = true
			//updateContacts.open()  UI crashes with this, needs more work
		}
	}	

    function onSyncClicked(){
        tabGroups.currentTab=waContacts;
        //loadingPage.operation="Refreshing Contacts"
        appWindow.pageStack.push(loadingPage);
        refreshContacts();
    }

    function onReloadingConversations(){
        waContacts.clearConversations();
        waChat.clearChats();
    }

    function onRefreshSuccess(){
        appWindow.pageStack.pop();
    }

    function onRefreshFail(){
        appWindow.pageStack.pop();
    }

	function onContactsSyncStatusChanged(state) {
		if (state=="GETTING") loadingPage.operation = qsTr("Retrieving contacts list...")
		else if (state=="SENDING") loadingPage.operation = qsTr("Fetching contacts...")
		else if (state=="LOADING") loadingPage.operation = qsTr("Loading contacts...")
		else loadingPage.operation = ""
	}

    function setIndicatorState(indicatorState){

        var showPoints = [waChat, waContacts]

       // waChat.indicator_state=indicatorState

        for(var p in showPoints){
            showPoints[p].indicator_state= indicatorState
        }

    }

    function getActiveConversation(){
        console.log(appWindow.pageStack.currentPage)
        if(appWindow.pageStack.currentPage.pageIdentifier && appWindow.pageStack.currentPage.pageIdentifier == "conversation_page")
        {
            return appWindow.pageStack.currentPage.user_id;

        }

        return 0;
    }

    function openConversation(jid){
        console.log("should open chat window with "+jid)

        if(getActiveConversation() != jid)
            waContacts.openChatWindow(jid)
    }

    function pushContacts(contacts){
        waChat.setContacts(contacts);
        waContacts.pushContacts(contacts)
    }
    function newMessage(msg_data){waContacts.newMessage(msg_data)}
    function forceRegistration(cc_val){regPage.cc_val=cc_val ;appWindow.pageStack.push(regPage)}
    function updateMessageStatus(msgKey,status){waContacts.updateMessageStatus(msgKey,status)}

    function messagesReady(messages)
    {
        waContacts.addMessage(messages.user_id, messages.data)
    }

    function onLastSeenUpdated(user_id,seconds){
        waContacts.onUnavailable(user_id,seconds);
    }

    function onAvailable(user_id){
        waContacts.onAvailable(user_id);
    }

    function onUnavailable(user_id){
        waContacts.onUnavailable(user_id);
    }

    function onTyping(user_id){
        waContacts.onTyping(user_id);
    }

    function onMessageSent(message_id,jid){
        waContacts.onMessageSent(message_id,jid);
        waChat.onMessageSent(message_id)
    }

    function onMessageDelivered(message_id,jid){
        waContacts.onMessageDelivered(message_id,jid);
        waChat.onMessageDelivered(message_id)
    }

    function onPaused(user_id){
        waContacts.onPaused(user_id);
    }

    function onRefreshing(){
        osd_notify.text="Refreshing";
        osd_notify.show();
    }


    function regSuccess()
    {
        console.log("REGISTRATION DONE!");
    }
    function regFail(reason)
    {
        console.log("REGISTRATION FAILED BECAUSE "+reason)
    }

    /*****************************************/

	ListModel {
		id: unreadModel
	}

    ListModel{
        id:chatsModel
    }

    ListModel{
        id:contactsModel
    }

    WAUpdate{
        id:updatePage
    }

    LoadingPage{
        id:loadingPage
    }


    function removeChatItem(cid){
        for (var i=0; i<chatsModel.count;i++)
        {
            console.log("deleting")
            var chatItem = chatsModel.get(i);
            console.log(chatItem.jid);
            if(chatItem.jid == cid)
            {
                chatsModel.remove(i)
                if(chatsModel.count == 0){
                    chatsContainer.state="no_data";
                }

                return;
            }
        }
    }


    Page {
        id: mainPage;
      // anchors.top: status_indicator.bottom

        tools: mainTools

		orientationLock: myOrientation==2 ? PageOrientation.LockLandscape:
						myOrientation==1 ? PageOrientation.LockPortrait : PageOrientation.Automatic


        TabGroup {
            id: tabGroups
            currentTab: waChat
          //  platformAnimated: true

            //Page
            Chats{
                id:waChat
                height: parent.height
                Component.onCompleted:  {
                    waChat.clicked.connect(waContacts.openChatWindow)
                    waChat.deleteConversation.connect(waContacts.deleteConversation)
                    waChat.deleteConversation.connect(appWindow.deleteConversation)

                }
            }
            //Page
            Contacts{
                id: waContacts
                height: parent.height

                Component.onCompleted: {
                    //connecting signals
                    waContacts.conversationUpdated.connect(waChat.updateConversation)
                    waContacts.sendMessage.connect(appWindow.sendMessage);
                    waContacts.sendTyping.connect(appWindow.sendTyping);
                    waContacts.sendPaused.connect(appWindow.sendPaused);

                }
            }
        }



        ToolBarLayout {

            id:mainTools

            ToolIcon{
                iconSource: "pics/wazapp48.png"
				platformStyle: ToolButtonStyle{inverted: stealth || theme.inverted}
            }

            ButtonRow {
                style: TabButtonStyle { inverted:stealth || theme.inverted }

                TabButton {
					id: chatsTabButton
                    platformStyle: TabButtonStyle{inverted: stealth || theme.inverted}
                    text: qsTr("Chats")
                    //iconSource: "../images/icon-m-toolbar-home.png"
                    tab: waChat
                }
                TabButton {
                 	platformStyle: TabButtonStyle{inverted: stealth || theme.inverted}
                    text: qsTr("Contacts")
                    // iconSource: "../images/icon-m-toolbar-list.png"
                    tab: waContacts
                }
            }

            ToolIcon {
                platformStyle: ToolButtonStyle{inverted: stealth || theme.inverted}
                id:toolbar_menu_item
                platformIconId: "toolbar-settings"
                //onClicked: (waMenu.status === DialogStatus.Closed) ? waMenu.open() : waMenu.close()
				onClicked: { pageStack.push (Qt.resolvedUrl("Settings.qml")) }

            }
        }



    }



    WAMenu {
        id: waMenu
        //onSyncClicked: {console.log("GOTCHA");refreshContacts()}
        Component.onCompleted: {
                waMenu.syncClicked.connect(onSyncClicked)

                }

        /*onAboutClicked: {
            aboutDialog.open();
        }*/

    }

    QueryDialog {
        id: updateContacts
        titleText: qsTr("Update Contacts")
        message: qsTr("The Phone contacts database has changed. Do you want to sync contacts now?")
        acceptButtonText: qsTr("Yes")
        rejectButtonText: qsTr("No")
        onAccepted: { updateContactsOpenend = false; syncClicked(); }
    }

    QueryDialog {
        id: quitConfirm
        titleText: qsTr("Confirm Quit")
        message: qsTr("Are you sure you want to quit Wazapp?")
        acceptButtonText: qsTr("Yes")
        rejectButtonText: qsTr("No")
        onAccepted: quit();
    }


    QueryDialog {
        id: updateDialog
        property string version;
        property string link;
        property string changes;
        property string severity;

        titleText: qsTr("Wazapp %1 is now available for update!").arg(version)
        message: "Urgency:"+severity+"\nSummary:\n"+changes
        acceptButtonText: qsTr("Details")
        rejectButtonText: qsTr("Cancel")
        onAccepted: appWindow.pageStack.push(updatePage);
    }

}
