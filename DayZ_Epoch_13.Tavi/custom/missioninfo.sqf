//WAI Mission Notification
MissionPos = _this select 0;
ActiveMissionName = _this select 1;
ActiveMissionText = _this select 2;

systemChat "A mission is available press 7 to view details...";
 
uiSleep 120; //Change time here again - makes sure that the information gets reset every 2 minutes, if you put the Weapon/Item down, the Information will be removed after max. x seconds
if if(!("ItemRadio" in weapons player)
{
    ActiveMissionText="";
    ActiveMissionName="No Missions Available";
};