(*************************************************************
* COPYRIGHT – B&R Industrial Automation
 *************************************************************
* PROGRAM: Milling Machine
* Author: Patrtyk Tomaszewski
* Created: 10/8/2020
*************************************************************
* Project Milling Machine
*************************************************************)

PROGRAM _INIT
	//Alarms
	MpAlarmXCore_0.MpLink := ADR(gAlarmXCore);
	MpAlarmXCore_0.Enable := TRUE;
	AckALL.MpLink := ADR(gAlarmXCore);
	AckALL.Enable := TRUE;
	//Alarm History

	MpAlarmXHistory_0.MpLink := ADR(gAlarmXHistory);
	MpAlarmXHistory_0.Enable := TRUE;
	MpAlarmXHistory_0.DeviceName := ADR('CF');

	
	//3 axis
	MpCnc3Axis_0.MpLink := ADR(gCncXYZ);
	MpCnc3Axis_0.Enable := TRUE;
	MpCnc3Axis_0.Parameters := ADR(CncParameters_3Axis);
	MpCnc3Axis_0.Override := 100.0;
	///////////////////////////////
	
	
	//X axis
	Xaxis.MpLink := ADR(gAxisQX);
	Xaxis.Parameters := ADR(X_param);
	Xaxis.Enable := TRUE;
	X_param.Velocity := 30.0;
	X_param.Acceleration := 50.0;
	X_param.Deceleration := 50.0;
	X_param.Homing.Mode := mcHOMING_DEFAULT;
   /////
	
	//Y axis
	Yaxis.MpLink := ADR(gAxisQY);
	Yaxis.Parameters := ADR(Y_param);
	Yaxis.Enable := TRUE;
	Y_param.Velocity := 30.0;
	Y_param.Acceleration := 50.0;
	Y_param.Deceleration := 50.0;
	Y_param.Homing.Mode := mcHOMING_DEFAULT;
	/////
	
	//Z axis
	Zaxis.MpLink := ADR(gAxisQZ);
	Zaxis.Parameters := ADR(Z_param);
	Zaxis.Enable := TRUE;
	Z_param.Velocity := 30.0;
	Z_param.Acceleration := 50.0;
	Z_param.Deceleration := 50.0;
	Z_param.Homing.Mode := mcHOMING_DEFAULT;
	/////
	
	//S axis
	Saxis.MpLink := ADR(gAxisQS);
	Saxis.Parameters := ADR(S_param);
	Saxis.Enable := TRUE;
	S_param.Velocity := 166.6;
	S_param.Acceleration := 400.0;
	S_param.Deceleration := 400.0;
	S_param.Homing.Mode := mcHOMING_DEFAULT;
	S_param.Jog.Velocity := 166.6;
	S_param.Jog.Acceleration := 400.0;
	S_param.Jog.Deceleration := 400.0;
	
	/////
	

END_PROGRAM

PROGRAM _CYCLIC
		
	(*  
	Powering On Servo*)
	
	CASE ServoStatus OF
		
		POWER_OFF:
			ActMode4MV := 'POWER OFF';
			MpCnc3Axis_0.Update := TRUE;
			Xaxis.Power := FALSE;
			Yaxis.Power := FALSE;
			Zaxis.Power := FALSE;
			Saxis.Power := FALSE;
			StopMode := FALSE;
			ManualON := FALSE;
			AutomaticON := FALSE;
			IF  MpCnc3Axis_0.Info.ReadyToPowerOn AND MpCnc3Axis_0.Power THEN
				MpCnc3Axis_0.Update := FALSE;
				ServoStatus := POWER_ON;
				
			END_IF
			
		POWER_ON:
			ActMode4MV := 'POWER ON';
			MpCnc3Axis_0.Update := TRUE;
			Xaxis.Power := TRUE;
			Yaxis.Power := TRUE;
			Zaxis.Power := TRUE;
			Saxis.Power := TRUE;
			IF  MpCnc3Axis_0.PowerOn AND Xaxis.PowerOn AND Yaxis.PowerOn AND Zaxis.PowerOn AND Saxis.PowerOn THEN;	
				MpCnc3Axis_0.Update := FALSE;
				ServoStatus := HOME;
				
			END_IF	
				
			
		HOME:
			ActMode4MV := 'Homing';
			MpCnc3Axis_0.Home := TRUE;
			IF  MpCnc3Axis_0.IsHomed AND Xaxis.Position = 0.0 AND Yaxis.Position = 0.0 AND Zaxis.Position = 300.0 THEN;
				ActMode4MV := 'Ready To Work';
				ServoStatus := READY_TO_WORK;
				
			END_IF
		READY_TO_WORK:
			MpCnc3Axis_0.Home := FALSE;
			
			
			CASE WorkingMode OF
				
				CHOOSE_MODE:
					IF AutomaticON THEN;
						WorkingMode := AUTOMATIC;
						Elements2Done := 0;
					ELSIF ManualON THEN;
						WorkingMode := MANUAL;
					END_IF
						
				AUTOMATIC:
					AutomaticON := TRUE;
					MpCnc3Axis_0.Power := TRUE;
					ManualON := FALSE;
					
					ActMode4MV := 'Automatic Mode';
					CASE AutoModeStatus OF
						////////Const X axis move until we find elem
						XMOVING:
							Elem2Small := FALSE;
							X_param.Velocity := 30.0;
							Xaxis.Update := TRUE;
							IF Sensor = FALSE THEN;
								Xaxis.Update := FALSE;
								Xaxis.MoveVelocity := TRUE;		
								IF StopMode THEN
									Xaxis.MoveVelocity := FALSE;
									AutomaticON := FALSE;
									NumOfElem := 0;
									WorkingMode := STOP;
	  
								END_IF;
							
							ELSE 
								gdoProcessLamp := TRUE;
								AutoModeStatus := ASIGNSTART;
							END_IF	
							///////////////////////////	
						
							///Calculate Length of element	
							
						ASIGNSTART:
							X_param.Velocity := 20.0;
							Xaxis.Update := TRUE;	
							LengthStart := Xaxis.Position;
							AutoModeStatus := ASIGNEND;
							
						ASIGNEND:
							Xaxis.Update := FALSE;
							IF Sensor = FALSE THEN;
								LengthEnd := Xaxis.Position;
								AutoModeStatus := CALCSIZE;	
							END_IF	
							
						CALCSIZE:
							ObjLength := LengthEnd - LengthStart;
							CentreX := LengthStart + (ObjLength / 2);
							AutoModeStatus := WORKING;
							/////////////////////////////////////
							
							///start program	
						WORKING:
							Xaxis.MoveVelocity := FALSE;	
							X_param.Velocity := 30.0;
							//Program I
							IF ChooseProgr = CAPITAL_I THEN
		
								IF ObjLength < 40 THEN
									Elem2Small := TRUE;
									gdoProcessLamp := FALSE;
									AutoModeStatus := XMOVING;
									
								ELSE
									X_param.Position := CentreX;
									Xaxis.Update := TRUE;
									Xaxis.MoveAbsolute := TRUE;	
									
									IF  Xaxis.InPosition  THEN;
										Xaxis.Update := FALSE;
										Xaxis.MoveAbsolute := FALSE;
										CncParameters_3Axis.ProgramName := 'IProg';
										MpCnc3Axis_0.Update := TRUE;
										MpCnc3Axis_0.MoveProgram := TRUE;
										IF MpCnc3Axis_0.MoveDone THEN	
											MpCnc3Axis_0.Update := FALSE;	
											MpCnc3Axis_0.MoveProgram := FALSE;
											X_param.Position := LengthEnd;
											Xaxis.Update := TRUE;
											Xaxis.MoveAbsolute := TRUE;
											IF Xaxis.InPosition THEN
												Xaxis.Update := FALSE;
												Xaxis.MoveAbsolute := FALSE;
												IF StopMode THEN
													AutomaticON := FALSE;
													gdoProcessLamp := FALSE;
													NumOfElem := 0;
													WorkingMode := STOP;////////going to stop mode after completing program
													
												ELSE
													gdoProcessLamp := FALSE;
													Elements2Done := Elements2Done + 1;
													IF (Elements2Done = NumOfElem) AND (NumOfElem <> 0.0) THEN;
														NumOfElem := 0;
														Elements2Done := 0;
														StopMode := TRUE;
														AutomaticON := FALSE;
														WorkingMode := STOP;
													ELSE 
														IF NumOfElem = 0.0 THEN;
															Elements2Done := FALSE;
															AutoModeStatus := XMOVING;
														ELSE
															AutoModeStatus := XMOVING;
														END_IF;
													END_IF;
												END_IF;
				
											END_IF;
										END_IF;
									END_IF;
								END_IF;	
								//Program i
							ELSIF ChooseProgr = SMALL_I THEN		

								IF ObjLength < 40 THEN
									Elem2Small := TRUE;
									gdoProcessLamp := FALSE;
									AutoModeStatus := XMOVING;
								ELSE
										
									X_param.Position := CentreX;
									Xaxis.Update := TRUE;
									Xaxis.MoveAbsolute := TRUE;
									IF Xaxis.InPosition THEN;
										Xaxis.Update := FALSE;
										Xaxis.MoveAbsolute := FALSE;
										CncParameters_3Axis.ProgramName := 'isProg'; 
										MpCnc3Axis_0.Update := TRUE;
										MpCnc3Axis_0.MoveProgram := TRUE;
										IF MpCnc3Axis_0.MoveDone THEN
											MpCnc3Axis_0.Update := FALSE;	
											MpCnc3Axis_0.MoveProgram := FALSE;
											X_param.Position := LengthEnd;
											Xaxis.Update := TRUE;
											Xaxis.MoveAbsolute := TRUE;
											IF Xaxis.InPosition THEN
												Xaxis.Update := FALSE;
												Xaxis.MoveAbsolute := FALSE;
												IF StopMode THEN
													gdoProcessLamp := FALSE;
													AutomaticON := FALSE;
													NumOfElem := 0;
													WorkingMode := STOP;////////going to stop mode after completing program
												ELSE
													gdoProcessLamp := FALSE;
													Elements2Done := Elements2Done + 1;
													IF (Elements2Done = NumOfElem) AND (NumOfElem <> 0.0) THEN;
														NumOfElem := 0;
														Elements2Done := 0;
														StopMode := TRUE;
														AutomaticON := FALSE;
														WorkingMode := STOP;
													ELSE 
														IF NumOfElem = 0.0 THEN;
															Elements2Done := FALSE;
															AutoModeStatus := XMOVING;
														ELSE
															AutoModeStatus := XMOVING;
														END_IF;
													END_IF;
												END_IF;
				  
											END_IF;
										END_IF;
									END_IF;
								END_IF;	
								///Program W
							ELSIF ChooseProgr = CAPITAL_W THEN
								IF ObjLength < 140 THEN
									Elem2Small := TRUE;
									gdoProcessLamp := FALSE;
									AutoModeStatus := XMOVING;
								ELSE
								
									X_param.Position := CentreX + 50;
									Xaxis.Update := TRUE;
									Xaxis.MoveAbsolute := TRUE;
									IF Xaxis.InPosition THEN;
										Xaxis.Update := FALSE;
										Xaxis.MoveAbsolute := FALSE;	
										CncParameters_3Axis.ProgramName := 'WProg'; 
										MpCnc3Axis_0.Update := TRUE;
										MpCnc3Axis_0.MoveProgram := TRUE;
										IF MpCnc3Axis_0.MoveDone THEN
											MpCnc3Axis_0.Update := FALSE;	
											MpCnc3Axis_0.MoveProgram := FALSE;
											X_param.Position := LengthEnd;
											Xaxis.Update := TRUE;
											Xaxis.MoveAbsolute := TRUE;
											IF Xaxis.InPosition  THEN
												Xaxis.Update := FALSE;
												Xaxis.MoveAbsolute := FALSE;
												IF StopMode THEN
													AutomaticON := FALSE;
													gdoProcessLamp := FALSE;
													NumOfElem := 0;
													WorkingMode := STOP;////////going to stop mode after completing program
												ELSE
													gdoProcessLamp := FALSE;
													Elements2Done := Elements2Done + 1;
													IF (Elements2Done = NumOfElem) AND (NumOfElem <> 0.0) THEN;
														NumOfElem := 0;
														Elements2Done := 0;
														StopMode := TRUE;
														AutomaticON := FALSE;
														WorkingMode := STOP;
													ELSE 
														IF NumOfElem = 0.0 THEN;
															Elements2Done := FALSE;
															AutoModeStatus := XMOVING;
														ELSE
															AutoModeStatus := XMOVING;
														END_IF;
													END_IF;
												END_IF;
				  
											END_IF;
										END_IF;
									END_IF;
								END_IF;
								///Program U
							ELSIF ChooseProgr = CAPITAL_U  THEN
								IF ObjLength < 115 THEN
									Elem2Small := TRUE;
									gdoProcessLamp := FALSE;
									AutoModeStatus := XMOVING;
								ELSE	
										
									X_param.Position := CentreX + 37.5;
									Xaxis.Update := TRUE;
									Xaxis.MoveAbsolute := TRUE;
									IF Xaxis.InPosition THEN;
										Xaxis.Update := FALSE;
										Xaxis.MoveAbsolute := FALSE;	
										CncParameters_3Axis.ProgramName := 'UProg'; 
										MpCnc3Axis_0.Update := TRUE;
										MpCnc3Axis_0.MoveProgram := TRUE;
										IF MpCnc3Axis_0.MoveDone THEN	
											MpCnc3Axis_0.Update := FALSE;	
											MpCnc3Axis_0.MoveProgram := FALSE;
											X_param.Position := LengthEnd;
											Xaxis.Update := TRUE;
											Xaxis.MoveAbsolute := TRUE;
											IF Xaxis.InPosition THEN
												Xaxis.Update := FALSE;
												Xaxis.MoveAbsolute := FALSE;
												IF StopMode THEN
													AutomaticON := FALSE;
													gdoProcessLamp := FALSE;
													NumOfElem := 0;
													WorkingMode := STOP;////////going to stop mode after completing program
												ELSE
													gdoProcessLamp := FALSE;
													Elements2Done := Elements2Done + 1;
													IF (Elements2Done = NumOfElem) AND (NumOfElem <> 0.0) THEN;
														NumOfElem := 0;
														Elements2Done := 0;
														StopMode := TRUE;
														AutomaticON := FALSE;
														WorkingMode := STOP;
													ELSE 
														IF NumOfElem = 0.0 THEN;
															Elements2Done := FALSE;
															AutoModeStatus := XMOVING;
														ELSE
															AutoModeStatus := XMOVING;
														END_IF;
													END_IF;
												END_IF;
				  
											END_IF;
										END_IF;
									END_IF;
								END_IF;
								//Program X
							ELSIF ChooseProgr = CAPITAL_X THEN	
								IF ObjLength < 115 THEN
									Elem2Small := TRUE;
									gdoProcessLamp := FALSE;
									AutoModeStatus := XMOVING;
								ELSE
										
									X_param.Position := CentreX + 37.5;
									Xaxis.Update := TRUE;
									Xaxis.MoveAbsolute := TRUE;
									IF  Xaxis.InPosition THEN;
										Xaxis.Update := FALSE;
										Xaxis.MoveAbsolute := FALSE;
										CncParameters_3Axis.ProgramName := 'XProg'; 
										MpCnc3Axis_0.Update := TRUE;
										MpCnc3Axis_0.MoveProgram := TRUE;
										IF MpCnc3Axis_0.MoveDone THEN;
											MpCnc3Axis_0.Update := FALSE;	
											MpCnc3Axis_0.MoveProgram := FALSE;
											X_param.Position := LengthEnd;
											Xaxis.Update := TRUE;
											Xaxis.MoveAbsolute := TRUE;
											IF Xaxis.InPosition THEN
												Xaxis.Update := FALSE;
												Xaxis.MoveAbsolute := FALSE;
												IF StopMode THEN
													AutomaticON := FALSE;
													gdoProcessLamp := FALSE;
													NumOfElem := 0;
													WorkingMode := STOP;////////going to stop mode after completing program
												ELSE
													gdoProcessLamp := FALSE;
													Elements2Done := Elements2Done + 1;
													IF (Elements2Done = NumOfElem) AND (NumOfElem <> 0.0) THEN;
														NumOfElem := 0;
														Elements2Done := 0;
														StopMode := TRUE;
														AutomaticON := FALSE;
														WorkingMode := STOP;
													ELSE 
														IF NumOfElem = 0.0 THEN;
															Elements2Done := FALSE;
															AutoModeStatus := XMOVING;
														ELSE
															AutoModeStatus := XMOVING;
														END_IF;
													END_IF;
												END_IF;
				  
											END_IF;
										END_IF;
									END_IF;
								END_IF;
								//Program R
							ELSIF ChooseProgr = CAPITAL_R THEN	
								IF ObjLength < 90 THEN
									Elem2Small := TRUE;
									gdoProcessLamp := FALSE;
									AutoModeStatus := XMOVING;
								ELSE
								
									X_param.Position := CentreX + 25;
									Xaxis.Update := TRUE;
									Xaxis.MoveAbsolute := TRUE;
									IF Xaxis.InPosition THEN;
										Xaxis.Update := FALSE;
										Xaxis.MoveAbsolute := FALSE;	
										CncParameters_3Axis.ProgramName := 'RProg'; 
										MpCnc3Axis_0.Update := TRUE;
										MpCnc3Axis_0.MoveProgram := TRUE;
										IF MpCnc3Axis_0.MoveDone THEN	
											MpCnc3Axis_0.Update := FALSE;	
											MpCnc3Axis_0.MoveProgram := FALSE;
											X_param.Position := LengthEnd;
											Xaxis.Update := TRUE;
											Xaxis.MoveAbsolute := TRUE;
											IF Xaxis.InPosition  THEN;
												Xaxis.Update := FALSE;
												Xaxis.MoveAbsolute := FALSE;
												IF StopMode THEN
													AutomaticON := FALSE;
													gdoProcessLamp := FALSE;
													NumOfElem := 0;
													WorkingMode := STOP;////////going to stop mode after completing program
												ELSE
													gdoProcessLamp := FALSE;
													Elements2Done := Elements2Done + 1;
													IF (Elements2Done = NumOfElem) AND (NumOfElem <> 0.0) THEN;
														NumOfElem := 0;
														Elements2Done := 0;
														StopMode := TRUE;
														AutomaticON := FALSE;
														WorkingMode := STOP;
													ELSE 
														IF NumOfElem = 0.0 THEN;
															Elements2Done := FALSE;
															AutoModeStatus := XMOVING;
														ELSE
															AutoModeStatus := XMOVING;
														END_IF;
													END_IF;
												END_IF;
				  
											END_IF;
											
										END_IF;
									END_IF;
								END_IF;	
							END_IF;
							
						
						
					END_CASE
			
				MANUAL:
					ManualON := TRUE;
					MpCnc3Axis_0.Power := TRUE;
					IF AutomaticON THEN;
						ManualON := FALSE;
						WorkingMode := AUTOMATIC;
						JogUpX := FALSE;
						JogDownX := FALSE;
						JogUpY := FALSE;
						JogDownY := FALSE;
						JogUpZ := FALSE;
						JogUpS := FALSE;
						Saxis.JogPositive := FALSE;
					END_IF;
					
					IF StopMode THEN;
						ManualON := FALSE;
						WorkingMode := STOP;
						JogUpX := FALSE;
						JogDownX := FALSE;
						JogUpY := FALSE;
						JogDownY := FALSE;
						JogUpZ := FALSE;
						JogUpS := FALSE;
						Saxis.JogPositive := FALSE;
						
					END_IF;
					
					ActMode4MV := 'Manual Mode';
					IF JogModeOn THEN;
						ManualModeStatus := JOG;
					ELSE
						ManualModeStatus := PRECISE;
					END_IF;
			
					CASE ManualModeStatus OF
						////Chossing which axis we want to move
						PRECISE:
							IF X2Move = FALSE AND Y2Move = FALSE AND Z2Move = FALSE AND S2Move = FALSE THEN;
								Moveaxis := FALSE;
							END_IF;
							CASE AsignProp OF
								AXIS2MOVE:
									IF X2Move THEN;
											X2Move := FALSE;
											Y2Move := FALSE;
											Z2Move := FALSE;
											S2Move := FALSE;
										AsignProp := MOVEX;
									ELSIF Y2Move THEN;
											X2Move := FALSE;
											Y2Move := FALSE;
											Z2Move := FALSE;
											S2Move := FALSE;
										AsignProp := MOVEY;
									ELSIF Z2Move THEN;
											X2Move := FALSE;
											Y2Move := FALSE;
											Z2Move := FALSE;
											S2Move := FALSE;
										AsignProp := MOVEZ;
									ELSIF S2Move THEN;
											X2Move := FALSE;
											Y2Move := FALSE;
											Z2Move := FALSE;
											S2Move := FALSE;
										AsignProp := MOVES;
									END_IF;
								MOVEX:
									IF Moveaxis THEN;
											
										X_param.Velocity := ManXVel;
										X_param.Position := ManXPos;
										Xaxis.MoveAbsolute := TRUE;	
										Moveaxis := TRUE;
										X2Move := TRUE;
										IF Xaxis.Position = ManXPos THEN;
											Moveaxis := FALSE;
											Xaxis.MoveAbsolute := FALSE;
											X2Move := FALSE;
											AsignProp := AXIS2MOVE;
										END_IF;
									END_IF;
								MOVEY:
									IF Moveaxis THEN;
										Y2Move := TRUE;			
										Y_param.Velocity := ManYVel;
										Y_param.Position := ManYPos;
										Yaxis.MoveAbsolute := TRUE;	
										Moveaxis := TRUE;
										IF Yaxis.Position = ManYPos THEN;
											Moveaxis := FALSE;
											Yaxis.MoveAbsolute := FALSE;	
											Y2Move := FALSE;
											AsignProp := AXIS2MOVE;
										END_IF;
									END_IF;
								MOVEZ:
									IF Moveaxis THEN;
										Z2Move := TRUE;		
										Z_param.Velocity := ManZVel;
										Z_param.Position := ManZPos;
										Zaxis.MoveAbsolute := TRUE;	
										Moveaxis := TRUE;
										IF Zaxis.Position = ManZPos THEN;
											Moveaxis := FALSE;
											Zaxis.MoveAbsolute := FALSE;
											Z2Move := FALSE;
											AsignProp := AXIS2MOVE;
										END_IF;
									END_IF;
								MOVES:
									IF Moveaxis THEN;
										S2Move := TRUE;					
										S_param.Velocity := ManSVel;
										S_param.Position := ManSPos;
										Saxis.MoveAbsolute := TRUE;
										Moveaxis := TRUE;
										IF Saxis.Position = ManSPos THEN;
											Moveaxis := FALSE;
											Saxis.MoveAbsolute := FALSE;
											S2Move := FALSE;
											AsignProp := AXIS2MOVE;
										END_IF;
									END_IF;
							END_CASE	
						JOG:
							CASE JogStatus OF
								JOGTYPE:
									IF JogUpX THEN;
										JogStatus := XUP;
									ELSIF JogDownX THEN;
										JogStatus := XDOWN;
									ELSIF JogUpY THEN;
										JogStatus := YUP;
									ELSIF JogDownY THEN;
										JogStatus := YDOWN;
									ELSIF JogUpZ THEN;
										JogStatus := ZUP;
									ELSIF JogDownZ THEN;
										JogStatus := ZDOWN;
									END_IF;
								XUP: 
									JogDownX := FALSE;
									JogUpY := FALSE;
									JogDownY := FALSE;
									JogUpZ := FALSE;
									JogDownZ := FALSE;
									Xaxis.JogPositive := TRUE;
									Xaxis.JogNegative := FALSE;
									Yaxis.JogPositive := FALSE;
									Yaxis.JogNegative := FALSE;
									Zaxis.JogPositive := FALSE;
									Zaxis.JogNegative := FALSE;
									IF JogUpX = FALSE THEN;
										Xaxis.JogPositive := FALSE;
										JogStatus := JOGTYPE;	
									END_IF;		
								XDOWN:
									JogUpX := FALSE;
									JogUpY := FALSE;
									JogDownY := FALSE;
									JogUpZ := FALSE;
									JogDownZ := FALSE;
									Xaxis.JogPositive := FALSE;
									Xaxis.JogNegative := TRUE;
									Yaxis.JogPositive := FALSE;
									Yaxis.JogNegative := FALSE;
									Zaxis.JogPositive := FALSE;
									Zaxis.JogNegative := FALSE;
									IF JogDownX = FALSE THEN;
										Xaxis.JogNegative := FALSE;
										JogStatus := JOGTYPE;	
									END_IF;			
								YUP:
									JogUpX := FALSE;
									JogDownX := FALSE;
									JogDownY := FALSE;
									JogUpZ := FALSE;
									JogDownZ := FALSE;
									Xaxis.JogPositive := FALSE;
									Xaxis.JogNegative := FALSE;
									Yaxis.JogPositive := TRUE;
									Yaxis.JogNegative := FALSE;
									Zaxis.JogPositive := FALSE;
									Zaxis.JogNegative := FALSE;
									IF JogUpY = FALSE THEN;
										Yaxis.JogPositive := FALSE;
										JogStatus := JOGTYPE;	
									END_IF;			
								YDOWN:
									JogUpX := FALSE;
									JogDownX := FALSE;
									JogUpY := FALSE;
									JogUpZ := FALSE;
									JogDownZ := FALSE;
									Xaxis.JogPositive := FALSE;
									Xaxis.JogNegative := FALSE;
									Yaxis.JogPositive := FALSE;
									Yaxis.JogNegative := TRUE;
									Zaxis.JogPositive := FALSE;
									Zaxis.JogNegative := FALSE;
									IF JogDownY = FALSE OR (Yaxis.Position = -100.0) THEN;
										Yaxis.JogNegative := FALSE;
										JogStatus := JOGTYPE;	
									END_IF;		
								ZUP:
									JogUpX := FALSE;
									JogDownX := FALSE;
									JogUpY := FALSE;
									JogDownY := FALSE;
									JogDownZ := FALSE;
									Xaxis.JogPositive := FALSE;
									Xaxis.JogNegative := FALSE;
									Yaxis.JogPositive := FALSE;
									Yaxis.JogNegative := FALSE;
									Zaxis.JogPositive := TRUE;
									Zaxis.JogNegative := FALSE;
									IF JogUpZ = FALSE THEN;
										Zaxis.JogPositive := FALSE;
										JogStatus := JOGTYPE;	
									END_IF;			
								ZDOWN:
									JogUpX := FALSE;
									JogDownX := FALSE;
									JogUpY := FALSE;
									JogDownY := FALSE;
									JogUpZ := FALSE;
									Xaxis.JogPositive := FALSE;
									Xaxis.JogNegative := FALSE;
									Yaxis.JogPositive := FALSE;
									Yaxis.JogNegative := FALSE;
									Zaxis.JogPositive := FALSE;
									Zaxis.JogNegative := TRUE;
									IF JogDownZ = FALSE THEN;
										Zaxis.JogNegative := FALSE;
										JogStatus := JOGTYPE;	
									END_IF;	
							END_CASE				

							IF JogUpS THEN;
								Saxis.JogPositive := TRUE;
							ELSE 
								Saxis.JogPositive := FALSE;
							END_IF;
						
					END_CASE
					///////////
					///////////////////
	
					//////////////////////
					////////////////////
				STOP:
					ActMode4MV := 'STOP Mode';
					Xaxis.Stop := TRUE;
					Yaxis.Stop := TRUE;
					Zaxis.Stop := TRUE;
					Saxis.Stop := TRUE;	
					IF (StopMode = FALSE) AND (Xaxis.Stop = TRUE) AND (Yaxis.Stop = TRUE) AND (Zaxis.Stop = TRUE) AND (Saxis.Stop = TRUE) THEN
						IF (AutomaticON = TRUE) AND (ManualON = FALSE) THEN;
							Xaxis.Stop := FALSE;
							Yaxis.Stop := FALSE;
							Zaxis.Stop := FALSE;
							Saxis.Stop := FALSE;
							IF (Xaxis.Stop = FALSE) AND (Yaxis.Stop = FALSE) AND (Zaxis.Stop = FALSE) AND (Saxis.Stop = FALSE) THEN;
								WorkingMode := AUTOMATIC;
								AutoModeStatus := XMOVING;
							END_IF;
						ELSIF (AutomaticON = FALSE) AND (ManualON = TRUE) THEN;
							WorkingMode := MANUAL;
							Xaxis.Stop := FALSE;
							Yaxis.Stop := FALSE;
							Zaxis.Stop := FALSE;
							Saxis.Stop := FALSE;
							IF (Xaxis.Stop = FALSE) AND (Yaxis.Stop = FALSE) AND (Zaxis.Stop = FALSE) AND (Saxis.Stop = FALSE) THEN;
								WorkingMode := MANUAL;
							END_IF;
						END_IF;
					ELSIF StopMode THEN;
						AutomaticON := FALSE;
						ManualON := FALSE;
					
					END_IF;
					IF EDGENEG(MpCnc3Axis_0.Power) THEN;
						AutomaticON := FALSE;
						ManualON := FALSE;
						StopMode := FALSE;
						Xaxis.Update := FALSE;
						IF MpCnc3Axis_0.PowerOn = FALSE THEN;
							WorkingMode := CHOOSE_MODE;
							ServoStatus := POWER_OFF;
							Xaxis.MoveVelocity := FALSE;
						END_IF;
					END_IF;	
				
			END_CASE
	
			
	END_CASE;
//Emergency Button	
	IF EDGEPOS (EmergStop) THEN;
		MpCnc3Axis_0.Power := FALSE;
		AutomaticON := FALSE;
		ManualON := FALSE;
		StopMode := FALSE;
		Xaxis.Update := FALSE;
			
	
		
	END_IF
	IF  WarningSymbol1 THEN
		EmergStop := TRUE;
		MpCnc3Axis_0.Power := FALSE;
		AutomaticON := FALSE;
		ManualON := FALSE;
		StopMode := FALSE;
	END_IF;
	
	IF EDGENEG (WarningSymbol1) THEN
		EmergStop := FALSE;
	END_IF
	IF EDGENEG (EmergStop) THEN;
		MpCnc3Axis_0.Power := FALSE;
		WorkingMode := CHOOSE_MODE;
		ServoStatus := POWER_OFF;
		Xaxis.MoveVelocity := FALSE;
	END_IF
	
/////////////////////////////////////////////////	
	
	
	//////////////////////////////////////
	//ALARMS
	//////////////////////////////////////
	IF EDGEPOS (EmergStop) THEN
		MpAlarmXSet (gAlarmXCore, 'EmergButton');
	END_IF
	IF EDGENEG (EmergStop) THEN
		MpAlarmXReset (gAlarmXCore, 'EmergButton');
	END_IF
	
	IF EDGEPOS (EmergStopAck) THEN
		MpAlarmXAcknowledge (gAlarmXCore, 'EmergButton');
		EmergStopAck := FALSE;
	END_IF
	
	
	
	IF EDGEPOS (Elem2Small) THEN
		MpAlarmXSet (gAlarmXCore, 'Elem2Small');
	END_IF
	IF EDGENEG (Elem2Small) THEN
		MpAlarmXReset (gAlarmXCore, 'Elem2Small');
	END_IF
	
	IF EDGEPOS (Elem2SmallAck) THEN
		MpAlarmXAcknowledge (gAlarmXCore, 'Elem2Small');
		Elem2SmallAck := FALSE;
	END_IF
	
	AckALL.Execute := AckAllButton;
	
	WarningSymbol1 := MpAlarmXCheckState(gAlarmXCore, 'EmergButton',mpALARMX_STATE_UNACKNOWLEDGED);
	WarningSymbol2 := MpAlarmXCheckState(gAlarmXCore, 'Elem2Small',mpALARMX_STATE_UNACKNOWLEDGED);
	
	IF WarningSymbol1 OR WarningSymbol2 THEN
		ShowWarning := TRUE;
		
	ELSE
		ShowWarning := FALSE;
		
	END_IF;
	///////////////////////////////////////////	
	
	/////////////////////////////////////////
	//Milling Lamp
	//////////////////////
	
	IF Saxis.Velocity = 0.0 THEN;
		gdoMillingLamp := FALSE;
	ELSE
		gdoMillingLamp := TRUE;
	END_IF;
	
	////////////////////////////////////////
	
	//////PLC Open State
	
	//Xaxis
	IF Xaxis.Info.PLCopenState = 0 THEN;
		XState := 'mpAXIS_DISABLED';
		XOff := FALSE;
		XOn := FALSE;
		Xmove := FALSE;
	ELSIF Xaxis.Info.PLCopenState = 1 THEN;
		XState := 'mpAXIS_STANDSTILL';
		XOff := FALSE;
		XOn := TRUE;
		Xmove := FALSE;
	ELSIF Xaxis.Info.PLCopenState = 2 THEN;
		XState := 'mpAXIS_ERRORSTOP';
		XOff := FALSE;
		XOn := FALSE;
		Xmove := FALSE;
	ELSIF Xaxis.Info.PLCopenState = 3 THEN;
		XState := 'mpAXIS_STOPPING';
		XOff := TRUE;
		XOn := FALSE;
		Xmove := FALSE;
	ELSIF Xaxis.Info.PLCopenState = 4 THEN;
		XState := 'mpAXIS_DISCRETE_MOTION';
		XOff := FALSE;
		XOn := FALSE;
		Xmove := FALSE;
	ELSIF Xaxis.Info.PLCopenState = 5 THEN;
		XState := 'mpAXIS_CONTINUOUS_MOTION';
		XOff := FALSE;
		XOn := FALSE;
		Xmove := TRUE;
	ELSIF Xaxis.Info.PLCopenState = 6 THEN;
		XState := 'mpAXIS_SYNCHRONIZED_MOTION';
		XOff := FALSE;
		XOn := FALSE;
		Xmove := TRUE;
	ELSIF Xaxis.Info.PLCopenState = 7 THEN;
		XState := 'mpAXIS_HOMING';
		XOff := FALSE;
		XOn := FALSE;
		Xmove := FALSE;
	END_IF;
	
	//Yaxis
	IF Yaxis.Info.PLCopenState = 0 THEN;
		YState := 'mpAXIS_DISABLED';
		YOff := FALSE;
		YOn := FALSE;
		Ymove := FALSE;
	ELSIF Yaxis.Info.PLCopenState = 1THEN;
		YState := 'mpAXIS_STANDSTILL';
		YOff := FALSE;
		YOn := TRUE;
		Ymove := FALSE;
	ELSIF Yaxis.Info.PLCopenState = 2 THEN;
		YState := 'mpAXIS_ERRORSTOP';
		YOff := FALSE;
		YOn := FALSE;
		Ymove := FALSE;
	ELSIF Yaxis.Info.PLCopenState = 3 THEN;
		YState := 'mpAXIS_STOPPING';
		YOff := TRUE;
		YOn := FALSE;
		Ymove := FALSE;
	ELSIF Yaxis.Info.PLCopenState = 4 THEN;
		YState := 'mpAXIS_DISCRETE_MOTION';
		YOff := FALSE;
		YOn := FALSE;
		Ymove := FALSE;
	ELSIF Yaxis.Info.PLCopenState = 5 THEN;
		YState := 'mpAXIS_CONTINUOUS_MOTION';
		YOff := FALSE;
		YOn := FALSE;
		Ymove := TRUE;
	ELSIF Xaxis.Info.PLCopenState = 6 THEN;
		YState := 'mpAXIS_SYNCHRONIZED_MOTION';
		YOff := FALSE;
		YOn := FALSE;
		Ymove := TRUE;
	ELSIF Xaxis.Info.PLCopenState = 7 THEN;
		YState := 'mpAXIS_HOMING';
		YOff := FALSE;
		YOn := FALSE;
		Ymove := FALSE;
	END_IF;
	
	//Zaxis
	IF Zaxis.Info.PLCopenState = 0 THEN;
		ZState := 'mpAXIS_DISABLED';
		ZOff := FALSE;
		ZOn := FALSE;
		Zmove := FALSE;
	ELSIF Zaxis.Info.PLCopenState = 1 THEN;
		ZState := 'mpAXIS_STANDSTILL';
		ZOff := FALSE;
		ZOn := TRUE;
		Zmove := FALSE;
	ELSIF Zaxis.Info.PLCopenState = 2 THEN;
		ZState := 'mpAXIS_ERRORSTOP';
		ZOff := FALSE;
		ZOn := FALSE;
		Zmove := FALSE;
	ELSIF Zaxis.Info.PLCopenState = 3 THEN;
		ZState := 'mpAXIS_STOPPING';
		ZOff := TRUE;
		ZOn := FALSE;
		Zmove := FALSE;
	ELSIF Zaxis.Info.PLCopenState = 4 THEN;
		ZState := 'mpAXIS_DISCRETE_MOTION';
		ZOff := FALSE;
		ZOn := FALSE;
		Zmove := FALSE;
	ELSIF Zaxis.Info.PLCopenState = 5 THEN;
		ZState := 'mpAXIS_CONTINUOUS_MOTION';
		ZOff := FALSE;
		ZOn := FALSE;
		Zmove := TRUE;
	ELSIF Zaxis.Info.PLCopenState = 6 THEN;
		ZState := 'mpAXIS_SYNCHRONIZED_MOTION';
		ZOff := FALSE;
		ZOn := FALSE;
		Zmove := TRUE;
	ELSIF Zaxis.Info.PLCopenState = 7 THEN;
		ZState := 'mpAXIS_HOMING';
		ZOff := FALSE;
		ZOn := FALSE;
		Zmove := FALSE;
	END_IF;
	
	//Saxis
	IF Saxis.Info.PLCopenState = 0 THEN;
		SState := 'mpAXIS_DISABLED';
		SOff := FALSE;
		SOn := FALSE;
		Smove := FALSE;
	ELSIF Saxis.Info.PLCopenState = 1 THEN;
		SState := 'mpAXIS_STANDSTILL';
		SOff := FALSE;
		SOn := TRUE;
		Smove := FALSE;
	ELSIF Saxis.Info.PLCopenState = 2 THEN;
		SState := 'mpAXIS_ERRORSTOP';
		SOff := FALSE;
		SOn := FALSE;
		Smove := FALSE;
	ELSIF Saxis.Info.PLCopenState = 3 THEN;
		SState := 'mpAXIS_STOPPING';
		SOff := TRUE;
		SOn := FALSE;
		Smove := FALSE;
	ELSIF Saxis.Info.PLCopenState = 4 THEN;
		SState := 'mpAXIS_DISCRETE_MOTION';
		SOff := FALSE;
		SOn := FALSE;
		Smove := FALSE;
	ELSIF Saxis.Info.PLCopenState = 5 THEN;
		SState := 'mpAXIS_CONTINUOUS_MOTION';
		SOff := FALSE;
		SOn := FALSE;
		Smove := TRUE;
	ELSIF Saxis.Info.PLCopenState = 6 THEN;
		SState := 'mpAXIS_SYNCHRONIZED_MOTION';
		SOff := FALSE;
		SOn := FALSE;
		Smove := TRUE;
	ELSIF Saxis.Info.PLCopenState = 7 THEN;
		SState := 'mpAXIS_HOMING';
		SOff := FALSE;
		SOn := FALSE;
		Smove := FALSE;
	END_IF;
	
	//////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	MpCnc3Axis_0();
	Xaxis();
	Yaxis();
	Zaxis();
	Saxis();
	MpAlarmXCore_0();
	AckALL();
	MpAlarmXHistory_0();
	
END_PROGRAM

PROGRAM _EXIT
	
	//Alarms
	MpAlarmXCore_0.Enable := FALSE;
	MpAlarmXCore_0();

	AckALL.Enable := FALSE;
	AckALL();
	
	
	MpAlarmXHistory_0.Enable := FALSE;
	MpAlarmXHistory_0();

	//3 Axis
	MpCnc3Axis_0.Power  := FALSE;
	MpCnc3Axis_0.Home   := FALSE;
	MpCnc3Axis_0.Enable := FALSE;
	MpCnc3Axis_0();
	/////
	
	//X axis
	Xaxis.Power  := FALSE;
	Xaxis.Home   := FALSE;
	Xaxis.MoveAbsolute := FALSE;
	Xaxis.MoveAdditive := FALSE;
	Xaxis.MoveVelocity := FALSE;
	Xaxis.Stop         := FALSE;
	Xaxis.ErrorReset   := FALSE;
	Xaxis();
	Xaxis.Enable := FALSE;
	Xaxis();
	/////////////////
	
	//Y axis
	Xaxis.Power  := FALSE;
	Xaxis.Home   := FALSE;
	Xaxis.MoveAbsolute := FALSE;
	Xaxis.MoveAdditive := FALSE;
	Xaxis.MoveVelocity := FALSE;
	Xaxis.Stop         := FALSE;
	Xaxis.ErrorReset   := FALSE;
	Xaxis();
	Xaxis.Enable := FALSE;
	Xaxis();
	/////////////////
	
	//Z axis
	Xaxis.Power  := FALSE;
	Xaxis.Home   := FALSE;
	Xaxis.MoveAbsolute := FALSE;
	Xaxis.MoveAdditive := FALSE;
	Xaxis.MoveVelocity := FALSE;
	Xaxis.Stop         := FALSE;
	Xaxis.ErrorReset   := FALSE;
	Xaxis();
	Xaxis.Enable := FALSE;
	Xaxis();
	/////////////////
	
	//S axis
	Xaxis.Power  := FALSE;
	Xaxis.Home   := FALSE;
	Xaxis.MoveAbsolute := FALSE;
	Xaxis.MoveAdditive := FALSE;
	Xaxis.MoveVelocity := FALSE;
	Xaxis.Stop         := FALSE;
	Xaxis.ErrorReset   := FALSE;
	Xaxis();
	Xaxis.Enable := FALSE;
	Xaxis();
	/////////////////
	 
END_PROGRAM

