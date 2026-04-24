/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_RigidJointDifferentialKinematics_info.c
 *
 * Code generation for function 'RigidJointDifferentialKinematics'
 *
 */

/* Include files */
#include "_coder_RigidJointDifferentialKinematics_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced54494ec330147550412c0a640327605d310854d875944a27d40904416d48dcd621"
      "b6abd881c225587106aec12d4042dc854e69dd4851828a8a807af3f3"
      "f2fef7f37fb63e9032790900b00e86ab111ec6b511964771094c2f372fb9f2a4e974b00c"
      "4253750eff388a1a251c76f9101015c371a54e31222ae195fb0e0416",
      "64d4bc85fa80692213561086651114fa08a7056a0cfa54ff3bd186da4dd9c6c06ab3c909"
      "4d118cfd78f3e83714d00feee187ece22f53578963a5caa0c51442d5"
      "b6a124a96663483853f2b14a2e1657cab444cb082b49d46c42abc720f5da8475e7775c65"
      "48ab376da2714409534aa885f4138a08170acc2c2210ab1c692c82c5",
      "3e3b33f619f6e9d3e1f5de5d62a4d17a5be5a27e6346fd154ffd21a353bb67d644ef6546"
      "bd860b03579ec37fffbd8a0e46b09f7f1b01fb71c749feea20465edf"
      "07d4bcf46acfc9ed79ea39eba7f4ba1efb057d8f9b1e7ab28bbf3e2f1e268c9db3a35a22"
      "df8ae2a4554cd1a8708e531f1dbf73000f3caffd17f33a589f5f9ed7",
      "aa6e88fa8d19f5ffe1bcee39f877e7f5d3c7fe625e83e0ef71cb434f76f1b052dd3b2854"
      "ef8cac964b171f76ad0b16cda47fffbcfe040a9e01cf",
      ""};
  nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(&data[0], 3192U, &nameCaptureInfo);
  return nameCaptureInfo;
}

mxArray *emlrtMexFcnProperties(void)
{
  mxArray *xEntryPoints;
  mxArray *xInputs;
  mxArray *xResult;
  const char_T *propFieldName[9] = {"Version",
                                    "ResolvedFunctions",
                                    "Checksum",
                                    "EntryPoints",
                                    "CoverageInfo",
                                    "IsPolymorphic",
                                    "PropertyList",
                                    "UUID",
                                    "ClassEntryPointIsHandle"};
  const char_T *epFieldName[8] = {
      "QualifiedName",    "NumberOfInputs", "NumberOfOutputs", "ConstantInputs",
      "ResolvedFilePath", "TimeStamp",      "Constructor",     "Visible"};
  xEntryPoints =
      emlrtCreateStructMatrix(1, 1, 8, (const char_T **)&epFieldName[0]);
  xInputs = emlrtCreateLogicalMatrix(1, 5);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("RigidJointDifferentialKinematics"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(5.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(12.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\RigidJointDifferentialKinematics.m"));
  emlrtSetField(xEntryPoints, 0, "TimeStamp",
                emlrtMxCreateDoubleScalar(739774.62395833328));
  emlrtSetField(xEntryPoints, 0, "Constructor",
                emlrtMxCreateLogicalScalar(false));
  emlrtSetField(xEntryPoints, 0, "Visible", emlrtMxCreateLogicalScalar(true));
  xResult =
      emlrtCreateStructMatrix(1, 1, 9, (const char_T **)&propFieldName[0]);
  emlrtSetField(xResult, 0, "Version",
                emlrtMxCreateString("24.2.0.2806996 (R2024b) Update 3"));
  emlrtSetField(xResult, 0, "ResolvedFunctions",
                (mxArray *)c_emlrtMexFcnResolvedFunctionsI());
  emlrtSetField(xResult, 0, "Checksum",
                emlrtMxCreateString("3e7mqxAyuGV045Fy4ae0AC"));
  emlrtSetField(xResult, 0, "EntryPoints", xEntryPoints);
  return xResult;
}

/* End of code generation (_coder_RigidJointDifferentialKinematics_info.c) */
