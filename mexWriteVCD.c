/*#########################################################################
    File Name:mexWriteVCD.c
    Version : v1.2
    Created By: Tabrez Alam (TAB)
    Last updated on 11 June,2012
    ----------------------------
        Change Log
    ----------------------------
    (1) Initial
    (2) v1.1 - Version change due to change in CreateVCD.m
    (3) v1.2 - Version change due to change in CreateVCD.m

#########################################################################*/

/**************************************************************************
 *  FUNTION INPUTS REQUIRED ARE
 *
 *  Test case name      STRING
 *  Date                STRING
 *  Time scale value    STRING
 *  Time unit           STRING
 *  TimeBuffer          CELL ARRAY
 *  SignalStruct        ARRAY OF STRUCT
 *  DataBuffer          CELL OF ARRAY CONTAINING STRING
 *  SigInfo             CELL OF STRUCT


 *  Fields of structure and arrays:

 *  SignalStruct(NoOfSig).Name
 *  SignalStruct(NoOfSig).Type
 *  SignalStruct(NoOfSig).Path
 *  SignalStruct(NoOfSig).ScopeHeader
 *  SignalStruct(NoOfSig).ScopeFooter

 *  SigInfo.VCDType
 *  SigInfo.VCDSize
 *  SigInfo.VCDValuePref
 *  SigInfo.VCDValueSuf
 *  SigInfo.VCDValueStrType
 *  SigInfo.VCDIdfr
**************************************************************************/


#include "mex.h"                                            /* Always include this */

#define MAX_INPUTS              8
#define MAX_OUTPUTS             0

#define FILE_NAME_IP_ID         0
#define DATE_STR_IP_ID          1
#define TIME_SCALE_IP_ID        2
#define TIME_UNIT_IP_ID         3
#define TIME_BUFFER_IP_ID       4
#define SIGNAL_STRUCT_IP_ID     5
#define DATA_BUFFER_IP_ID       6
#define SIGNAL_INFO_IP_ID       7

#define STRINGS_EQUAL           0


void mexFunction(int nlhs, mxArray *plhs[],                 /* Output variables */
                 int nrhs, const mxArray *prhs[])           /* Input variables */
{

    /*---------------------------------------------------------
        Common variables
    ---------------------------------------------------------*/
    unsigned long y, x;
    int sig_changed;

    /*---------------------------------------------------------
        Define variables to store required data
    ---------------------------------------------------------*/
    mxChar *FileName;
    mxChar *DateStr;
    mxChar *TimeScaleStr;
    mxChar *TimeUnit;

    /*---------------------------------------------------------
        Variables for TimeBuffer
    ---------------------------------------------------------*/
    mxArray *TimeBuffer_ptr;
    mxArray *TimeBuffer_Value_ptr;
    mxChar *TimeBuffer_Value;
    size_t TimeBufferM;

    /*---------------------------------------------------------
        Variables for signal struct
    ---------------------------------------------------------*/
    mxArray *SignalStruct_ptr;

    mxArray *SignalStruct_Name_ptr;
    mxChar *SignalStruct_Name;

    mxArray *SignalStruct_Type_ptr;
    mxChar *SignalStruct_Type;

    mxArray *SignalStruct_Path_ptr;
    mxChar *SignalStruct_Path;

    mxArray *SignalStruct_ScopeHeader_ptr;
    mxChar *SignalStruct_ScopeHeader;

    mxArray *SignalStruct_ScopeFooter_ptr;
    mxChar *SignalStruct_ScopeFooter;
    
    size_t SignCount;

    /*---------------------------------------------------------
        Variables for DataBuffer
    ---------------------------------------------------------*/
    mxArray *DataBuffer_ptr;
    mxArray *DataBuffer_Element_ptr;
    mxArray *DataBuffer_Value_ptr;
    mxChar *DataBuffer_Value;
    mxChar *DataBuffer_Value_Last;

    /*---------------------------------------------------------
        Variables for SigInfo Cell array
    ---------------------------------------------------------*/
    mxArray *SigInfo_ptr;

    mxArray *SigInfo_struct_ptr;

    mxArray *SigInfo_VCDType_ptr;
    mxChar *SigInfo_VCDType;

    mxArray *SigInfo_VCDSize_ptr;
    mxChar *SigInfo_VCDSize;

    mxArray *SigInfo_VCDValuePref_ptr;
    mxChar *SigInfo_VCDValuePref;

    mxArray *SigInfo_VCDValueSuf_ptr;
    mxChar *SigInfo_VCDValueSuf;

    mxArray *SigInfo_VCDIdfr_ptr;
    mxChar *SigInfo_VCDIdfr;

    /*---------------------------------------------------------
        Create a file pointer
    ---------------------------------------------------------*/
    FILE *Fid;

    /*---------------------------------------------------------
        Check for proper number of input arguments
    ---------------------------------------------------------*/
    if (nrhs > MAX_INPUTS)
    {
        mexErrMsgTxt("Only 8 input arguments are required");
    }
    else if (nrhs == 0)
    {
        mexErrMsgTxt("Please supply the inputs.");
    }

    /*---------------------------------------------------------
        Check for proper number of output arguments
    ---------------------------------------------------------*/
    if(nlhs != 0)
    {
        mexErrMsgTxt("This function not returns any output argument.");
    }


    /*---------------------------------------------------------
        Read FileName
    ---------------------------------------------------------*/
    FileName = mxArrayToString(prhs[FILE_NAME_IP_ID]);

    /*---------------------------------------------------------
        Read Date string
    ---------------------------------------------------------*/
    DateStr  = mxArrayToString(prhs[DATE_STR_IP_ID]);

    /*---------------------------------------------------------
        Read Time scale value string
    ---------------------------------------------------------*/
    TimeScaleStr = mxArrayToString(prhs[TIME_SCALE_IP_ID]);

    /*---------------------------------------------------------
        Read Time scale unit
    ---------------------------------------------------------*/
    TimeUnit = mxArrayToString(prhs[TIME_UNIT_IP_ID]);

    /*---------------------------------------------------------
        Copy the time series array
    ---------------------------------------------------------*/
    TimeBuffer_ptr = prhs[TIME_BUFFER_IP_ID];
    TimeBufferM = mxGetM(TimeBuffer_ptr);

    /*---------------------------------------------------------
        Copy the signal struct arrays
    ---------------------------------------------------------*/
    SignalStruct_ptr = prhs[SIGNAL_STRUCT_IP_ID];
    SignCount = mxGetNumberOfElements(SignalStruct_ptr);

    /*---------------------------------------------------------
        Copy the Data buffer
    ---------------------------------------------------------*/
    DataBuffer_ptr = prhs[DATA_BUFFER_IP_ID];

    /*---------------------------------------------------------
        Copy the signal info cell array
    ---------------------------------------------------------*/
    SigInfo_ptr = prhs[SIGNAL_INFO_IP_ID];

    /*---------------------------------------------------------
        Create and open the file
    ---------------------------------------------------------*/
    Fid = fopen(FileName, "wt");

    /*---------------------------------------------------------
        Wrire General comment
    ---------------------------------------------------------*/
    fprintf(Fid,"$comment\nVCD file generated by CreateVCD tool\n$end\n\n");

    /*---------------------------------------------------------
        Wrire Header section
    ---------------------------------------------------------*/
    fprintf(Fid,"$date %s $end\n\n",DateStr);
    fprintf(Fid,"$version Simulink verification $end\n\n");

    /*---------------------------------------------------------
        Wrire variable defination section
    ---------------------------------------------------------*/
    fprintf(Fid,"$timescale %s %s $end\n\n",TimeScaleStr,TimeUnit);

    //fprintf(Fid,"$scope module Model $end\n\n");

    //fprintf(Fid,"$scope module Inputs $end\n");

    /*---------------------------------------------------------
        Write signal defination section
    ---------------------------------------------------------*/
    for(x=0; x<SignCount; x++)
    {
        
        SignalStruct_Name_ptr = mxGetField(SignalStruct_ptr, x, "Name");
        SignalStruct_Name = mxArrayToString(SignalStruct_Name_ptr);
        
        SignalStruct_ScopeHeader_ptr = mxGetField(SignalStruct_ptr, x, "ScopeHeader");
        SignalStruct_ScopeHeader = mxArrayToString(SignalStruct_ScopeHeader_ptr);
        
        SignalStruct_ScopeFooter_ptr = mxGetField(SignalStruct_ptr, x, "ScopeFooter");
        SignalStruct_ScopeFooter = mxArrayToString(SignalStruct_ScopeFooter_ptr);
        
        SigInfo_struct_ptr = mxGetCell(SigInfo_ptr,x);

        SigInfo_VCDType_ptr = mxGetField(SigInfo_struct_ptr, 0, "VCDType");
        SigInfo_VCDType = mxArrayToString(SigInfo_VCDType_ptr);

        SigInfo_VCDSize_ptr = mxGetField(SigInfo_struct_ptr, 0, "VCDSize");
        SigInfo_VCDSize = mxArrayToString(SigInfo_VCDSize_ptr);

        SigInfo_VCDIdfr_ptr = mxGetField(SigInfo_struct_ptr, 0, "VCDIdfr");
        SigInfo_VCDIdfr = mxArrayToString(SigInfo_VCDIdfr_ptr);
        
        fprintf(Fid,"%s\n",SignalStruct_ScopeHeader);
        fprintf(Fid,"$var %s %s %s %s $end\n",SigInfo_VCDType,SigInfo_VCDSize,SigInfo_VCDIdfr,SignalStruct_Name);
        fprintf(Fid,"%s\n",SignalStruct_ScopeFooter);
    }

    fprintf(Fid,"\n$enddefinitions $end\n\n");

    /*---------------------------------------------------------
        Write data for all signals at all time
    ---------------------------------------------------------*/
    for(x=0; x<TimeBufferM; x++)
    {
        TimeBuffer_Value_ptr = mxGetCell(TimeBuffer_ptr,x);
        TimeBuffer_Value = mxArrayToString(TimeBuffer_Value_ptr);

        fprintf(Fid,"#%s\n",TimeBuffer_Value);

        for(y = 0; y<SignCount; y++)
        {
            // Get the data value
            DataBuffer_Element_ptr = mxGetCell(DataBuffer_ptr,y);
            DataBuffer_Value_ptr = mxGetCell(DataBuffer_Element_ptr,x);
            DataBuffer_Value = mxArrayToString(DataBuffer_Value_ptr);
        
            // Only write if there was a change
            if(x > 0)
            {
                DataBuffer_Value_ptr = mxGetCell(DataBuffer_Element_ptr,x-1);
                DataBuffer_Value_Last = mxArrayToString(DataBuffer_Value_ptr);
                
                if( strcmp(DataBuffer_Value_Last, DataBuffer_Value) == 0)
                {
                    sig_changed = false;
                } else {
                    sig_changed = true;
                }
            } else {
                sig_changed = true;
            }
            
            if( sig_changed > 0)
            {
                SigInfo_struct_ptr = mxGetCell(SigInfo_ptr,y);

                SigInfo_VCDValuePref_ptr = mxGetField(SigInfo_struct_ptr, 0, "VCDValuePref");
                SigInfo_VCDValuePref = mxArrayToString(SigInfo_VCDValuePref_ptr);

                SigInfo_VCDValueSuf_ptr = mxGetField(SigInfo_struct_ptr, 0, "VCDValueSuf");
                SigInfo_VCDValueSuf = mxArrayToString(SigInfo_VCDValueSuf_ptr);

                SigInfo_VCDIdfr_ptr = mxGetField(SigInfo_struct_ptr, 0, "VCDIdfr");
                SigInfo_VCDIdfr = mxArrayToString(SigInfo_VCDIdfr_ptr);



                fprintf(Fid,"%s%s%s%s\n", SigInfo_VCDValuePref,
                                          DataBuffer_Value,
                                          SigInfo_VCDValueSuf,
                                          SigInfo_VCDIdfr);
            }
        }
     }

    /*---------------------------------------------------------
        Write dumpoff to stop signal dumping
    ---------------------------------------------------------*/
    fprintf(Fid,"\n$dumpoff\n");

    /*---------------------------------------------------------
        Close the file
    ---------------------------------------------------------*/
    fclose(Fid);

    return;
}



