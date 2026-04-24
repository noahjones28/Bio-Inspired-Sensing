/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_SoftJointKinematics_Z2_info.c
 *
 * Code generation for function 'SoftJointKinematics_Z2'
 *
 */

/* Include files */
#include "_coder_SoftJointKinematics_Z2_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced54cb4ec240141d0c1a17a86cf40b5c13c568d01d50499067e4a1c11a28edd44eed"
      "cc90cea0e84fb8f21bfc0d3fc19d0be3bf581e8532490583c1a8cce6"
      "f6f4dc9973ef99c90581742e00005807fd550cf5e3da00870771098c2f910f087981f174"
      "b00c8263fb5cfe6110554a38ecf03e200a86c39d1ac588288497ef5a",
      "10d89051eb066a3d4647162c230c4b5e90ef229cf25043d0a5badf4903aad7a53606b6c1"
      "46155a5e30f4e3c5a7dfe0947e983e7e8405fee2f83279245718b499"
      "4ca86298b244d53686843339172f67e309b9444f6909615942ba0e6d87414ad38275f777"
      "426148adeb6da272440973d2757e4211e119442056385259bd168de0",
      "f1fe5a33f6179ad09fcb6bce1d62a4d2baa170af7e6346fd155ffd3ea3d1b663d248ef79"
      "46bd86808190e7f2df7f9f5e072378927f1b53f623c651fe6a2f465e"
      "df7ad4bcf4aa4fd2f63cf5dcf5537a1d9ff3a67d8f9b3e7a61816f9e170e92e6ced96135"
      "99bb8a61c92e1cd398a78ee2049d4975001f3caff31773faf3febe3c",
      "a715cdf4ea3766d4ff8773da71f0efcee9c7f7bdc59c06d3bfc72d1fbdb0c0c37225ba9f"
      "afdc9a19359b2adcefda35164ba77eff9cfe00aeaef90e",
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
  xInputs = emlrtCreateLogicalMatrix(1, 4);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("SoftJointKinematics_Z2"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(4.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(8.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\SoftJointKinematics_Z2.m"));
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

/* End of code generation (_coder_SoftJointKinematics_Z2_info.c) */
