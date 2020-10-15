
TYPE
	JogStatusEnum : 
		(
		JOGTYPE,
		XUP,
		XDOWN,
		YUP,
		YDOWN,
		ZUP,
		ZDOWN
		);
	WorkingModeEnum : 
		(
		CHOOSE_MODE,
		AUTOMATIC,
		MANUAL,
		STOP
		);
	ServoStatusEnum : 
		(
		POWER_OFF := 0,
		POWER_ON := 1,
		HOME := 2,
		READY_TO_WORK := 3
		);
	AutoModeStatusEnum : 
		(
		XMOVING,
		WORKING,
		ASIGNSTART,
		CALCSIZE,
		ASIGNEND
		);
	ChooseProgrEnum : 
		(
		CAPITAL_I := 0,
		SMALL_I := 1,
		CAPITAL_W := 2,
		CAPITAL_U := 3,
		CAPITAL_X := 4,
		CAPITAL_R := 5
		);
	ManualModeStatusEnum : 
		(
		JOG,
		PRECISE
		);
	AsignPropEnum : 
		(
		AXIS2MOVE,
		MOVEX,
		MOVEY,
		MOVEZ,
		MOVES
		);
END_TYPE
