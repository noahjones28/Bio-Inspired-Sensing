/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_RigidJointKinematics_info.c
 *
 * Code generation for function 'RigidJointKinematics'
 *
 */

/* Include files */
#include "_coder_RigidJointKinematics_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced54cb4ec240149d1a342e50bbd12f704d7c4483aee42109f23250d0680d9476a083"
      "9d19d2298afe842bbfc1df70e91fb830fe8b50282d131baa188c86bb"
      "b93d3d77e6dcc7e402219d130000ab606047e1815f196271e817c0b8f1bcc0c509e3e160"
      "1184c6ce39fcc3d0ab9458b06b0d0051301c9dd4284644219674d786",
      "c0848c1a3750b3990632a084302c7941be8f70ca438d409fea7f2774a85e973a18983a73"
      "3334bc60d48f179f7a4301fba1fbf443e4f8cbe3abc4a15c66d06432"
      "a18ade929354ed60482c26e762523616974bb4484b08cb49d46840b3c720a56ec0aaf33b"
      "ae30a4561b1da25a881226175113692714112b8308c48a855416c14e",
      "5ded29eb0a4fa8cbe1b5deec3052695557ece13afab529f5977cf5078c463bbde6b87acf"
      "53ead5380cb83887fff9397a3be8cecfd1e3f35d0b580fefddf865db"
      "475edf6c6a567a95a7e4e62cf51cfb2dbdaecf7d41dfe3ba8f9ec8f1f5f3c27ea2b57576"
      "5049e49a519c340bc734eac9e37482cea43c800f9ed5fdf3fdfc795d",
      "5fdecf8ad6eae3f97efef67eee75f0ffeee7c7f7ddf97e06c1dfe3868f9ec8f1502aefec"
      "e5cbb7ad8c9a4d15eeb7cd0b164da7fefe7efe00d375f7b6",
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
  xInputs = emlrtCreateLogicalMatrix(1, 3);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("RigidJointKinematics"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(3.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(8.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\RigidJointKinematics.m"));
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

/* End of code generation (_coder_RigidJointKinematics_info.c) */
