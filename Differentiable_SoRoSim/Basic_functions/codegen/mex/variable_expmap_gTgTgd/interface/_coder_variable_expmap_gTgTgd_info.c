/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_variable_expmap_gTgTgd_info.c
 *
 * Code generation for function 'variable_expmap_gTgTgd'
 *
 */

/* Include files */
#include "_coder_variable_expmap_gTgTgd_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced54cb4ec240141d0c1a17a8dde817b8263ea24177d04242e4155bd0684d19da01a6"
      "329da60f447fc295dfe06ff809ee5c18ffc54229b44d2a35188c8fe9"
      "e2cee9b93367ee99c90589623901005807eea8a5dcb836c6cc382e81e008f389505e2298"
      "0e964132b0cee3efc751a69a8506960b3448d064a54209d6a06609b7",
      "3a02063269af8f9411d3c63d246082783fa80c1129f8a8091852c339db45f2356f136074"
      "cde9097b7e30f1e339a2de644c3fd4083f98107f99bf628fc5ba890c"
      "53d428ecaa2247659b20cd32c57256286573224f4f298f89c8e1761b190e8361ab8724ef"
      "770e9a5896dab6265b986aa6d887869b80063a81bad4119c4f499360",
      "7dfa9cf5a566d4e7f18a738704cb54ea42cbafdf9c537f2552df65146a3b1e4cf59ee6d4"
      "6b863008e579fcd7dfa7dfc13499e5df46cc7ac2719abf3a8ae997d7"
      "11b528bdc623b7bd483d6f7c97de2062bfb8ef7133428f09f1adf3ea21abee9c1d35d872"
      "274338a39aa719df396a3374669d0344e045edffdfa73faeefd37d1a",
      "2aaa5fbf39a7fe1fecd38e83bfb74f3fbcedfff76910ff3d6e45e831211e09f5bd834afd"
      "463d914b85eaddae7161668a859fdfa7df0158a2f988",
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
  xInputs = emlrtCreateLogicalMatrix(1, 2);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("variable_expmap_gTgTgd"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(2.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(3.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\variable_expmap_gTgTgd.m"));
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

/* End of code generation (_coder_variable_expmap_gTgTgd_info.c) */
