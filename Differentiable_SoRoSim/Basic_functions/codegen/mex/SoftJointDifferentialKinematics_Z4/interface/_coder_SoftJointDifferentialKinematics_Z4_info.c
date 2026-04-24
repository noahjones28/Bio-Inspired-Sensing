/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_SoftJointDifferentialKinematics_Z4_info.c
 *
 * Code generation for function 'SoftJointDifferentialKinematics_Z4'
 *
 */

/* Include files */
#include "_coder_SoftJointDifferentialKinematics_Z4_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced55dd4ec230182d068d17a8dce813784dfc0f7a070312e4cf3840833330b64e8a6b"
      "4bd60dd197f0ca67f0357c0b4d8cefe236181b4b16a6188c86de7c3b"
      "3b5f7bfa7d6d4e41245f8a0000d6c170b462c3b836c2f1515c0293c3cf477c7991c974b0"
      "0ca213f31cfe7114254a7438d0878088188e67ca14232212bd7adf83",
      "40838caa7d28db8c8254584518f25e50b610ce79a831b028eb9beb40e9963730d03accdd"
      "a1ea05e37ebc05d41b0dd98f7e403fe23efe2a7bcd9d083506352610"
      "2a76ba42864a068644674229552da6d2024fcf298fb090418a02359341625b854de7775a"
      "64486a2a069174440933d315fd9422a27bf2d50222108b3a9258b371",
      "90c06e9dbd19eb8c4da9d3e165f32c3192685394bb161edfbb19f55702f5878c4c0db359"
      "aedecb8c7a2d1f06be3c87fff973f5763081a7f56f23643dfee8e6af"
      "da31f1fa6e53f3d27bfad8df9ea79e337e4b6f10b05ed8fbb815a017f7f1b05adb3b2cd7"
      "eeba05a998ab3cec6a0d96cce7dc7d9c4dd199b60f1080e7b5fec2af",
      "c3d5f965bfee88f6e3bcf0eb6ffbb5d9c1ffebd7f5e7ccc2af41f8fbb819a017f7f1edcb"
      "ca11d7ddb938ae73a59b24ce68952c4d82bfefd79fee1a030b",
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
  xInputs = emlrtCreateLogicalMatrix(1, 8);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("SoftJointDifferentialKinematics_Z4"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(8.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(12.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\SoftJointDifferentialKinematics_Z4.m"));
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

/* End of code generation (_coder_SoftJointDifferentialKinematics_Z4_info.c) */
