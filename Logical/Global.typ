
TYPE
	InType : 	STRUCT 
		gdiStopButton : BOOL; (*emergency mechine stopping (INPUT)*)
		gdiObjSensor : BOOL; (*the vaule is TRUE if sensor detects object (INPUT)*)
	END_STRUCT;
	OutType : 	STRUCT 
		gdoMillingLamp : BOOL; (*Lamp is on ig milling cutter is revolving (OUTPUT)*)
		gdoProcessLamp : BOOL; (*Lamp is ON if obj is being processed (OUTPUT)*)
	END_STRUCT;
END_TYPE
