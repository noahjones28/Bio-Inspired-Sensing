/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_variable_expmap_gTg_info.c
 *
 * Code generation for function 'variable_expmap_gTg'
 *
 */

/* Include files */
#include "_coder_variable_expmap_gTg_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced54cb4ec240149d1a342e50bbd12f704d7c4483ae8402099187b1058dd6c0d84ecb"
      "60a7d3b405d19f70e537f81b2efd0317c67fb1500aa5b1691583d130"
      "9bdbd37367cebd77260730c53203005805ee3a4aba716588d9615c00932bc833813c6632"
      "1d2c82c4c43e8f7f184689ea36ead92ed02141a39d32255887ba2ddc",
      "190898c8a25a17c90346c11a123041bc1f54fa88147cd408f4a9fe37d742d20ddf21c06c"
      "59e30a353f18cde325a4df44cc79a821f36003fc65fe8a3b146b1632"
      "2d51a7b0d5167354ea10a4db9658ce08a54c56e4e929e5311173585190e930185e6ba8e1"
      "fdce420b4b0da5a34b36a6ba2576a1e926a09e41a0d150053545467d",
      "1953f6958ce8cbe365e7ee089668a3050797ebe937a7d45f0ad5771999769cdec77acf53"
      "ea35031804f23cfee7efd13fc114899adf5acc7e82719cbf3c88a9d7"
      "b701352bbdfa536e73967adefa2dbd5ec87971dfe37a881e1be0afcfabfb5c7bebeca0ce"
      "95d534c999d53c4dfbea3889d089aa0384e0599d3ff7e7cffbfab23f",
      "43b9ddc7737ffeb63f3b13fcbffefcf8be3bf76710ff3d6e84e8b1011e09b59dbd4aedb6"
      "7d2c950ad5fb6df3c24a170b7fdf9f3f005613f71e",
      ""};
  nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(&data[0], 3160U, &nameCaptureInfo);
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
  xInputs = emlrtCreateLogicalMatrix(1, 1);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("variable_expmap_gTg"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(1.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(2.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\variable_expmap_gTg.m"));
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

/* End of code generation (_coder_variable_expmap_gTg_info.c) */
