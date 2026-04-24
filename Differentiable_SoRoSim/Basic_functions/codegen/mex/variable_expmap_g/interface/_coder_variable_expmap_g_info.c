/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_variable_expmap_g_info.c
 *
 * Code generation for function 'variable_expmap_g'
 *
 */

/* Include files */
#include "_coder_variable_expmap_g_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[4] = {
      "789cc553414ec240141d0c1217a26cbc816be2caa03b683131113116d1c4316568a774b0"
      "33d3745a524fe115dc790d97dec08597115a064a93494950fc9bdfd7"
      "f767de7fffb7a074d92901000e401a6f953457e7b836cf3b6035f27c499165ec82f2ca39"
      "c9bfceb3c55988e330050c51bc3869734a186261efc5c720c0827b13",
      "6c278c433cdc23141b59703d43f422432dc08c9a3d6b2eb69e8d8882c015cb0ebd2c58cc"
      "e353e1b7bce63c700e835c9de41fdb4fda39bc1338109071e48ea1ce"
      "ad8862160ad869f6ae9a2d68f05b6e100a75e238389832040d3d6ccad72d2488653a11b3"
      "42c299801314a40538f629f2cd519d667cf91bfada2ff025797bba3b",
      "4a2c6eba2859aed41f6ca85f51eaa78ccda3a9f7a5dec7867a831c06b93ac9fffe1eb313"
      "acd3a2f91daee947f59f56c15e92eb5fdf09b52dbdfebb7ebc4d3d19"
      "ffa5172bee5bf77b3c52e8d572fcf0a17baa8d4feecffa5a67d4a07ad06df346a68f9b02"
      "9da23e8002fff5fd3f50628d51",
      ""};
  nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(&data[0], 1720U, &nameCaptureInfo);
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
                emlrtMxCreateString("variable_expmap_g"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(1.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(1.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\variable_expmap_g.m"));
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
                emlrtMxCreateString("XOmzitEu0gVFUhpzkEuGvG"));
  emlrtSetField(xResult, 0, "EntryPoints", xEntryPoints);
  return xResult;
}

/* End of code generation (_coder_variable_expmap_g_info.c) */
