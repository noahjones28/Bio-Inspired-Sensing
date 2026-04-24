/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_SoftJointKinematics_Z4_info.c
 *
 * Code generation for function 'SoftJointKinematics_Z4'
 *
 */

/* Include files */
#include "_coder_SoftJointKinematics_Z4_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced54cb4ec240141d0c1a17a86cf40b5c13df41774021415ec6021aac81d24e652a33"
      "433a83a23fe1ca6ff037fc04772e8cff627914da492a180c46e56e6e"
      "4fcf9d3973ef4c0e08a4730100c02ae8c749a89f5706383cc80bc01b221f10ea02de72b0"
      "08829e750eff30c81a251c76781f1015c3e14a9d624454c28b772d08",
      "2cc868f306ea3dc6404d584418ca6e90ef229c725143d0a5badf8906d4aee5360656838d"
      "4ed87483e13c5e7cfa0d4e380fd3671e6181bf485e268e9412831653"
      "08551ba62251ad8d21e14cc9c58ad9585c91e929951156246418d0b219a4d69bb0eafc8e"
      "ab0c6955a34d348e286176b9c18f29223c8308c42a471aab56f622d8",
      "db5f6bcafe4263fa7378ddbe438c345a5575d3ad5f9b527fc957bfcfe8b46d0f69a4f73c"
      "a55e4dc040a873f8efbf4ff7042378dcfcd626ec47cca3fae55e8ebc"
      "bef5a859e93dbeef6ece52cf899fd2ebf8ec37e97bdcf0d10b0b3c2c9676f6f3a55b33a3"
      "655385fb6dabc2a2e994cbf7c7e88c3b07f0c1b3da7feed39ff7f765",
      "9f6ea8dcad5f9b52ff1ffab43dc1bfebd3e52769eed360f2f7b8eea31716f8fa79e12061"
      "6e9d1d9613b9ab2896ac429246c1eff7e90f31bcf912",
      ""};
  nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(&data[0], 3176U, &nameCaptureInfo);
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
  xInputs = emlrtCreateLogicalMatrix(1, 6);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("SoftJointKinematics_Z4"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(6.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(8.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\SoftJointKinematics_Z4.m"));
  emlrtSetField(xEntryPoints, 0, "TimeStamp",
                emlrtMxCreateDoubleScalar(739774.62396990741));
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

/* End of code generation (_coder_SoftJointKinematics_Z4_info.c) */
