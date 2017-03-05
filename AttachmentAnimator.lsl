/**********************************************************
 * Basic Animator by Bellimora Resident                   *
 * https://github.com/Bellimora/bento_animator/           *
 * Distributed via AGPL v3.0 keep this script full perm   *
 **********************************************************/

//CONFIGURATION
float INTERVAL_MIN = 15.0; //a random number between 0 and INTERVAL_RANDOM is 
float INTERVAL_RANDOM = 30.0; //added to INTERVAL_RANDOM to set how long each time
                            //to wait between swapping idle animations
                            //so these default values are anytime between 15-45 seconds

list IDLES = ["BWs1", "BWs2", "BWs3", "BWs4"];
string WALK = "BWs1";
string SITTING = "BWs3";
string CROUCH = "BWsit";
string HOVER = "BWhover";
string FLY_UP = "BWhover";
string FLY_DOWN = "BWhover";
string FLYING = "BWfly";
string IN_AIR = "BWjump";
string RUNNING = "BWs4";
float INTERVAL = 0.3; //sets the speed of the updates.  0.3 is once every 0.3 seconds
float REASSERT = 300.0; //sets how long  in secondsthe script waits before it forces 
                        //the current animation to reset  this prevents outside people 
                        //from seeing your attachment as unaimated and jutting out.

//END CONFIGURATION

string Current;
string LastIdle;
float NextIdle;
string CurrentIdle;
float ReassertTime;

RandomIdle() {
    StopCurrent();
    CurrentIdle = llList2String(IDLES, (integer)llFrand(llGetListLength(IDLES)));
    SetAnim(CurrentIdle);
    NextIdle = llGetTime() + llFrand(INTERVAL_RANDOM) + INTERVAL_MIN;
}

SetAnim(string animation) {
    if (llGetTime() < ReassertTime) {
        if (Current == animation) return;
    }
    StopCurrent();
    Current = animation;
    llStartAnimation(Current);
    ReassertTime = llGetTime() + REASSERT;
}

StopCurrent() {
    if (Current) llStopAnimation(Current);
}

SetFly() {
    vector flySpeed = llGetVel();
    float horizontalSpeed = llVecMag(<flySpeed.x, flySpeed.y, 0.0>);
    if (flySpeed.z > horizontalSpeed * 2.0) SetAnim(FLY_UP);
    else if (llFabs(flySpeed.z) > horizontalSpeed * 2.0) SetAnim(FLY_DOWN);
    else if (horizontalSpeed > 1.0) SetAnim(FLYING);
    else SetAnim(HOVER);
}

default
{
    state_entry() {
        if (llGetAttached()) llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);
    }
    
    on_rez(integer n) {
        if (llGetAttached()) llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION| PERMISSION_TAKE_CONTROLS);
        else llSetTimerEvent(0.0);
    }

    run_time_permissions(integer perm) {
        if (perm) {
            ReassertTime = 0.0;
            llResetTime();
            RandomIdle();
            llSetTimerEvent(INTERVAL);
            llTakeControls(CONTROL_UP, TRUE, TRUE); //taking controls keeps a script running in no-script zones
            //so, don't remove the take controls line unless you like the attachment icing up in no-script zones
        }
    }
    
    timer() {
        if (!llGetAttached()) return;
        integer status = llGetAgentInfo(llGetOwner());
        if (status & AGENT_FLYING) SetFly();
        else if (status & AGENT_IN_AIR) SetAnim(IN_AIR);
        else if (status & AGENT_CROUCHING) SetAnim(CROUCH);
        else if (status & AGENT_WALKING) {
            if (status & AGENT_ALWAYS_RUN) SetAnim(RUNNING);
            else SetAnim(WALK);
        } else if (status & (AGENT_SITTING | AGENT_ON_OBJECT)) SetAnim(SITTING);
        else if (llGetTime() > NextIdle) RandomIdle();
        else SetAnim(CurrentIdle);
    }
}
