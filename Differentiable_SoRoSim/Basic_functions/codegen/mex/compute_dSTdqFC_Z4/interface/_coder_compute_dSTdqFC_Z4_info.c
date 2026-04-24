/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_compute_dSTdqFC_Z4_info.c
 *
 * Code generation for function 'compute_dSTdqFC_Z4'
 *
 */

/* Include files */
#include "_coder_compute_dSTdqFC_Z4_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[4] = {
      "789cc5934b4ec33010865d542a3685b2e104acbbe221b1a269a9406a2b206151300aaeed"
      "282eb15de204855370158ec10d5870199a26e923c84aa596329bc9ef"
      "2fceccfca380d255b70400d805497c54925c4d752dcd5b6031f2bca4c9596c83f2c2bd8c"
      "bfa7194b11d0284884409c4e6f12c9994022b0de4614f85449ef9592",
      "097198472dc6a9392f7ab1e2ed393415318a9f9b2ec5cf66c881efaa5987debc98faf1a9"
      "99b7bca41f8ec68f5a8e3f5c3c36cfe09da2be82422277085b12879c"
      "8a40c16ec3ea340c68ca5b69320e5bcc71a83f260c0d3c6a67c706520cdb4e2870c0a450"
      "104b3e0a036a13d3222feda67d7f54e7b3b9a215e7da2f982be364bc",
      "3bceb0b4b1446438407e7a9ef5f1b4621f156d1f0921321c9bb4be7dd29c06b9f732befe"
      "7dfe72325e67a18f7b4bcea5fb6fab606792eb5fdf13b4a97aa7e7c6"
      "e126eb65f15ff556fd1f0f34f56a397e6258fd7e8fb8375623ba3cee0a8f8c9c8e31ebe3"
      "baa04e511f40a3fffafb3fbbcf9182",
      ""};
  nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(&data[0], 1736U, &nameCaptureInfo);
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
  xInputs = emlrtCreateLogicalMatrix(1, 10);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("compute_dSTdqFC_Z4"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(10.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(1.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\compute_dSTdqFC_Z4.m"));
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
                emlrtMxCreateString("yPR2oIRKgabigCLqvhmHPF"));
  emlrtSetField(xResult, 0, "EntryPoints", xEntryPoints);
  return xResult;
}

/* End of code generation (_coder_compute_dSTdqFC_Z4_info.c) */
