/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#ifdef __cplusplus
#define YG_EXTERN_C_BEGIN extern "C" {
#define YG_EXTERN_C_END }
#else
#define YG_EXTERN_C_BEGIN
#define YG_EXTERN_C_END
#endif

#ifdef _WINDLL
#define WIN_EXPORT __declspec(dllexport)
#else
#define WIN_EXPORT
#endif

#ifndef YOGA_EXPORT
#ifdef _MSC_VER
#define YOGA_EXPORT
#else
#define YOGA_EXPORT __attribute__((visibility("default")))
#endif
#endif

#ifdef NS_ENUM
#define YG_ENUM_BEGIN(name) NS_ENUM(NSUInteger, name)
#define YG_ENUM_END(name)
#else
#define YG_ENUM_BEGIN(name) enum name
#define YG_ENUM_END(name) name
#endif

#ifdef NS_OPTIONS
#define YG_OPTIONS_BEGIN(name) NS_OPTIONS(NSUInteger, name)
#define YG_OPTIONS_END(name)
#else
#define YG_OPTIONS_BEGIN(name) enum name
#define YG_OPTIONS_END(name) name
#endif

#ifdef __GNUC__
#define YG_DEPRECATED __attribute__((deprecated))
#elif defined(_MSC_VER)
#define YG_DEPRECATED __declspec(deprecated)
#elif __cplusplus >= 201402L
#if defined(__has_cpp_attribute)
#if __has_cpp_attribute(deprecated)
#define YG_DEPRECATED [[deprecated]]
#endif
#endif
#endif
