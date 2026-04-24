/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_compute_dSTdqFC_Z2R_info.c
 *
 * Code generation for function 'compute_dSTdqFC_Z2R'
 *
 */

/* Include files */
#include "_coder_compute_dSTdqFC_Z2R_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[4] = {
      "789cc593cd4ec24010c71783c40b8a179fc033071335f1240589264094d603baa62ebb5b"
      "bbd8ddc57e98fa14be8a8fe11b78f0652cf403a8d99404c4b94cfffb"
      "eb7666fe9382d255b70400d805717c54e25c4d742dc95b6031f2bca4c8696c83f2c2bd94"
      "bf27194be1d3d08f85409c663789e44c20e11b6f630a5cea49e79592",
      "29b198430dc6a93e2f7a13c5db7328131334796eda143feb0107aeedcd3a74e645e6c7a7"
      "62def2927e3c29fca8e5f8fdc543f30cde7ad4f5a090c81ec196c401"
      "a7c2f760b761741a1ad4655fea8cc316b32cea4684a1a143cdf458431ec3a61508ec3329"
      "3c88251f073e35896e909776d3bc3bead7793657b8e25cfb0573a59c",
      "44bbe30c4b134b444643e426e7691f8f2bf65151f611132283c8a4f5ed93e634c8bd97f2"
      "f5eff39793d1368b7ddc5b722ed57f5b053bd35cfffa9ea24dd53b3d"
      "d70e37592f8dffaab7eaff78a0a857cbf113cd180c7ac4be311ae1e5715738646c75b459"
      "1fd705758afa000afdd7dfff014ac091d4",
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
  xInputs = emlrtCreateLogicalMatrix(1, 7);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("compute_dSTdqFC_Z2R"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(7.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(1.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\compute_dSTdqFC_Z2R.m"));
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

/* End of code generation (_coder_compute_dSTdqFC_Z2R_info.c) */
