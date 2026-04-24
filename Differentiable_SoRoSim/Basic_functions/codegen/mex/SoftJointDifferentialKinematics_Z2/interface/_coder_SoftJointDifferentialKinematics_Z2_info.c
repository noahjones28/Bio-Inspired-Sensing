/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_SoftJointDifferentialKinematics_Z2_info.c
 *
 * Code generation for function 'SoftJointDifferentialKinematics_Z2'
 *
 */

/* Include files */
#include "_coder_SoftJointDifferentialKinematics_Z2_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[5] = {
      "789ced54cb4ec240141d0c1a17a86cf40b5c13c568d01dcf0479192968b0064a3bb5533b"
      "33a4d322fa13aefc067fc3bfd0c4f82f96426969d250c56034cce6f6"
      "f4dc9973ef9dc9019162250200d804a3d5898de2c618c7c771054c2f3f1ff1e545a6d3c1"
      "2a884eed73f8c771142931e0c01801226038d929518c88400ceebe07",
      "810e19d5fa50b2191969904318d6bda03a44b8e0a12660480dbfb30a146feb2606bac2dc"
      "0a352f98cce32da0df68c879f403e611f7f157f9ebec09df6050673c"
      "a182a2f2392a9a181283f19534574e67f83a3da77584f91c9265a85b0c12ba1a6c3bbf33"
      "0243625b368968204a98952e1ba71411c393af951081583090c8daad",
      "6402bb7df6e6ec3336a34f8797acbbc448a46d45b02f7bf2eee6d45f0bd41f311235ad61"
      "b97a2f73ea757c18f8f21cfee7efd53bc1049e35bfad90fdf8a39bbf"
      "6ec7c4ebbb4d2d4aaff99cdb5da49eb37e4b6f10705ed8f7b81da017f7f1ddcbda5156dd"
      "bb386e662b37299cd36b799af2d471364367561d20002feafca55f87",
      "ebf3cb7e2d48ea102ffdfadb7e6d4df0fffaf5d3c7c1d2af41f8f7b813a017f7f1906b24"
      "0fab8d3bb524960bb5877dbdc552c5c2dff7eb4f637b0307",
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
  xInputs = emlrtCreateLogicalMatrix(1, 6);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("SoftJointDifferentialKinematics_Z2"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(6.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(12.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Users\\noahj\\Documents\\MATLAB\\SoRoSim\\Differentiable_"
          "SoRoSim\\Basic_functions\\SoftJointDifferentialKinematics_Z2.m"));
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

/* End of code generation (_coder_SoftJointDifferentialKinematics_Z2_info.c) */
