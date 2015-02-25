/*
   by: http://infiSTAR.de || http://DayzAntiHack.com
   *updated on 07.10.2014
    
    Instructions:
    1. Copy paste this pastebin code into a file called SafeZone.sqf - save the file.
    2. Now extract your mpmission pbo and put the SafeZone.sqf into the extracted folder.
    3. Open the init.sqf of the mpmission.
    4. At the bottom of the file add
    [] execVM 'SafeZone.sqf';
    5. Save the init.sqf, repack your mpmission, upload it to your gameserver and restart your server
*/
USE_CANBUILD = false;        // if you don't want to define your own positions
USE_TraderCity = false;    //    if you don't want to define your own positions (Epoch 1.0.5)
USE_POSITIONS = true;    // to use own positions and radius
USE_AI_REMOVER = false;    // use this to remove Missionbots (AI) within 100m of a player if the player is in a SafeZone
USE_AntiSteal = true;    // use this to block opening gear if another player is within 3m!
USE_SPEEDLIMIT = true;    // very secret function, nobody is supposed to find out what it does.
    SPEEDLIMIT = 20;        // Only used if USE_SPEEDLIMIT is true.
USE_SIGNS = true;        // use this to build signs around the SafeZone
LOG_EnterLeave = true;    // This will log to your .rpt when a player enters or leaves a SafeZone! (only works with infiSTAR.de Admintools / AntiHack)
/* You can use USE_CANBUILD or/and (works together) the custom positions below (USE_POSITIONS) [position or zone,radius] */
_infiSZ =
[
    [[15309.663,9278.4912],40,true],// zonesabina
    [[11698.81,15210.121],50,true],// zonelyep
    [[5538.7354,8762.2695],50,true],// zonebilgrad
    [[7376.6084,4296.5879],60,true],// zonebranibor
    [[15586.9,0.00143814],50,true],// zeonbilgrad	
	[[16673.4,11627.5],50,true],//hero
    [[16555.732,10159.68],20,true],// Aircraft Dealer 1
    [[6815.0776,8534.1504],20,true],// Aircraft Dealer
    [[4066.3528,7265.0024],20,true],// Misc. Vendor
    [[17497.631,7159.0879],20,true],// Misc. Vendor 1
    [[17332.115,12930.239],20,true],// Boat Dealer
    [[10570.494,16772.477],20,true],// Boat Dealer 1
    [[10698.463,5983.665],20,true],// Boat Dealer 2
    [[5419.2437,9503.5479],20,true],// Boat Dealer 3
    [[13342.758,8611.9932],20,true],// Wholesaler
    [[9859.4209,7471.5684],20,true]// Wholesaler 1
];
if (isServer) exitWith
{
    if (USE_SIGNS) then
    {
        {
            _center = _x select 0;
            _radius = _x select 1;
            _lSign = _x select 2;
            if (_lSign) then
            {
                for '_i' from 0 to 360 step (270 / _radius)*2 do
                {
                    _location = [(_center select 0) + ((cos _i) * _radius), (_center select 1) + ((sin _i) * _radius),0];
                    _dir = ((_center select 0) - (_location select 0)) atan2 ((_center select 1) - (_location select 1));
                    _object = createVehicle ['Sign_sphere100cm_EP1', _location, [], 0, 'CAN_COLLIDE'];
                    //    _object = createVehicle ['SignM_FARP_Winchester_EP1', _location, [], 0, 'CAN_COLLIDE'];
                    //    _object setVehicleInit 'this setObjectTexture [0,''Addons\SafeZones\sign.paa''];';
                    _object setDir _dir;
                };
            };
        } forEach _infiSZ;
    };
};
waitUntil {((!isNil 'dayz_animalCheck') || (!isNil 'dayz_medicalH') || (!isNil 'dayz_slowCheck') || (!isNil 'dayz_gui'))};
if (isNil 'inSafeZone') then { inSafeZone = false; } else { if (typename inSafeZone != 'BOOL') then { inSafeZone = false; }; };
[_infiSZ] spawn {
    _infiSZ = _this select 0;
    _startSafeZone =
    {
        if (isNil 'outNow') then
        {
            _msg = 'You entered a Safe Zone!';
            hint _msg;
            taskHint [_msg, [0,1,0,1], 'taskDone'];
            inNow = nil;
            outNow = true;
            
            if (LOG_EnterLeave) then
            {
                PVDZE_send = [player,'SafeZoneState',[1]];
                publicVariableServer 'PVDZE_send';
            };
        };
        player_fired = {
            deleteVehicle (nearestObject [_this select 0,_this select 4]);
            cutText ['You can not fire in a SafeZone!','WHITE IN'];
        };
        fnc_usec_damageHandler = {};
        player removeAllEventHandlers 'handleDamage';
        player addEventHandler ['handleDamage', {false}];
        player allowDamage false;
        _veh = vehicle player;
        if (player != _veh) then
        {
            _szs = _veh getVariable ['inSafeZone',0];
            if (_szs == 0) then
            {
                _veh removeAllEventHandlers 'Fired';
                _veh addEventHandler ['Fired', {_this call player_fired;}];
                {
                    _x removeAllEventHandlers 'Fired';
                    _x addEventHandler ['Fired', {_this call player_fired;}];
                } forEach (crew _veh);
                _veh setVariable ['inSafeZone',1];
                vehicle_handleDamage = {false};
                _veh removeAllEventHandlers 'HandleDamage';
                _veh addeventhandler ['HandleDamage',{ _this call vehicle_handleDamage } ];
                _veh allowDamage false;
            };
        };
        _notInSafeZone =
        [
            'MAAWS','RPG7V','M136','RPG18','STINGER',
            'MeleeHatchet_DZE','MeleeHatchet','MeleeCrowbar','MeleeMachete','MeleeFishingPole','MeleeSledge',
            'MeleeBaseBallBatNails','MeleeBaseBallBatBarbed','MeleeBaseBallBat'
        ];
        _cwep = currentWeapon player;
        if (_cwep in _notInSafeZone) then
        {
            _swep = '';
            {
                if ((getNumber (configFile >> 'CfgWeapons' >> _x >> 'Type')) == 2) exitWith
                {
                    _swep = _x;
                };
            } forEach (weapons player);
            if (_swep == '') then
            {
                player playActionNow 'PutDown';
                _iPos = getPosATL player;
                _radius = 1;
                _removed = ([player,_cwep,1] call BIS_fnc_invRemove);
                if (_removed == 1) then
                {
                    _item = createVehicle ['WeaponHolder', _iPos, [], _radius, 'CAN_COLLIDE'];
                    _item addWeaponCargoGlobal [_cwep,1];
                };
            }
            else
            {
                player selectweapon _swep;
            };
        };
    };
    _endSafeZone =
    {
        if (isNil 'inNow') then
        {
            if (str fnc_usec_damageHandler == '{}') then
            {
                _msg = 'You left the Safe Zone!';
                hint _msg;
                taskHint [_msg, [1,0,0.1,1], 'taskFailed'];
            };
            inNow = true;
            outNow = nil;
            
            if (LOG_EnterLeave) then
            {
                PVDZE_send = [player,'SafeZoneState',[0]];
                publicVariableServer 'PVDZE_send';
            };
        };
        player_fired = compile preprocessFileLineNumbers '\z\addons\dayz_code\compile\player_fired.sqf';
        player_zombieCheck = compile preprocessFileLineNumbers '\z\addons\dayz_code\compile\player_zombieCheck.sqf';
        fnc_usec_unconscious = compile preprocessFileLineNumbers '\z\addons\dayz_code\compile\fn_unconscious.sqf';
        object_monitorGear = compile preprocessFileLineNumbers '\z\addons\dayz_code\compile\object_monitorGear.sqf';
        vehicle_handleDamage = compile preprocessFileLineNumbers '\z\addons\dayz_code\compile\vehicle_handleDamage.sqf';
        
        _veh = vehicle player;
        if (player != _veh) then
        {
            _szs = _veh getVariable ['inSafeZone',0];
            if (_szs == 1) then
            {
                _veh setVariable ['inSafeZone',0];
                _veh removeAllEventHandlers 'HandleDamage';
                _veh addeventhandler ['HandleDamage',{ _this call vehicle_handleDamage } ];
                _veh allowDamage true;
            };
        };
        
        _end = false;
        if (isNil 'gmadmin') then
        {
            _end = true;
        }
        else
        {
            if (gmadmin == 0) then
            {
                _end = true;
            };
        };
        if (_end) then
        {
            player allowDamage true;
            fnc_usec_damageHandler = compile preprocessFileLineNumbers '\z\addons\dayz_code\compile\fn_damageHandler.sqf';
            player removeAllEventHandlers 'HandleDamage';
            player addeventhandler ['HandleDamage',{_this call fnc_usec_damageHandler;} ];
        };
    };
    while {1 == 1} do
    {
        if (isNil 'inSafeZone') then { inSafeZone = false; } else { if (typename inSafeZone != 'BOOL') then { inSafeZone = false; }; };
        _state = false;
        if (isNil 'USE_POSITIONS') then { USE_POSITIONS = false; } else { if (typename USE_POSITIONS != 'BOOL') then { USE_POSITIONS = false; }; };
        if (USE_POSITIONS) then
        {
            {
                _z = _x select 0;
                _r = _x select 1;
                if ((vehicle player) distance _z < _r) then {_state = true;};
            } forEach _infiSZ;
        };
        if (isNil 'USE_CANBUILD') then { USE_CANBUILD = true; } else { if (typename USE_CANBUILD != 'BOOL') then { USE_CANBUILD = true; }; };
        if (USE_CANBUILD) then
        {
            if (isNil 'canbuild') then { canbuild = true; } else { if (typename canbuild != 'BOOL') then { canbuild = true; }; };
            if (!canbuild) then {_state = true;};
        };
        if (isNil 'USE_TraderCity') then { USE_TraderCity = true; } else { if (typename USE_TraderCity != 'BOOL') then { USE_TraderCity = true; }; };
        if (USE_TraderCity) then
        {
            if (isNil 'isInTraderCity') then { isInTraderCity = false; } else { if (typename isInTraderCity != 'BOOL') then { isInTraderCity = false; }; };
            if (isInTraderCity) then {_state = true;};
        };
        if (_state) then
        {
            inSafeZone = true;
            call _startSafeZone;
            {
                if (!isNull _x) then
                {
                    if !(isPlayer _x) then
                    {
                        deletevehicle _x;
                    };
                };
            } forEach ((vehicle player) nearEntities ['zZombie_Base',15]);
            
            if (isNil 'USE_AI_REMOVER') then { USE_AI_REMOVER = false; } else { if (typename USE_AI_REMOVER != 'BOOL') then { USE_AI_REMOVER = false; }; };
            if (USE_AI_REMOVER) then
            {
                {
                    if ((!isNull group _x) && (getPlayerUID _x == '')) then
                    {
                        deleteVehicle _x;
                    };
                } forEach (player nearEntities ['Man',100]);
            };
        }
        else
        {
            inSafeZone = false;
        };
        uiSleep 2;
        if (!inSafeZone) then
        {
            call _endSafeZone;
        };
    };
};
if ((USE_AntiSteal) || (USE_SPEEDLIMIT)) then
{
    [] spawn {
        _USE_AntiSteal = USE_AntiSteal;
        _USE_SPEEDLIMIT = USE_SPEEDLIMIT;
        _speedlimit = SPEEDLIMIT;
        while {1 == 1} do
        {
            if (inSafezone) then
            {
                if (_USE_AntiSteal) then
                {
                    _cnt = {isPlayer _x && _x != player} count (player nearEntities [['CAManBase'], 3]);
                    if ((_cnt > 0) && (!isNull (findDisplay 106))) then
                    {
                        (findDisplay 106) closedisplay 0;
                        closeDialog 0;
                        _log = format['%1 You are not allowed to open Gear while near another player!',name player];
                        cutText [_log,'PLAIN'];
                        hint _log;
                    };
                };
                if (_USE_SPEEDLIMIT) then
                {
                    _obj = vehicle player;
                    if !(_obj isKindOf 'Plane') then
                    {
                        _speed = abs speed _obj;
                        if ((_obj != player) && (_speed > _speedlimit)) then
                        {
                            _vel = velocity _obj;
                            _x = 0.8;
                            if (_speed > 50) then {_x = 0.1;};
                            _velNew = [(_vel select 0) * _x, (_vel select 1) * _x,(_vel select 2) * _x];
                            _obj SetVelocity _velNew;
                        };
                    };
                };
            }
            else
            {
                uiSleep 2;
            };
            uiSleep 0.1;
        };
    };
};