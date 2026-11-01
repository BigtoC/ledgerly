// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'csv_import.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CsvRowError {

/// 1-based physical line in the file; the header is line 1.
 int get lineNumber; CsvRowErrorReason get reason;/// The unknown code, for [CsvRowErrorReason.unknownCurrency]; null
/// otherwise.
 String? get currencyCode;
/// Create a copy of CsvRowError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvRowErrorCopyWith<CsvRowError> get copyWith => _$CsvRowErrorCopyWithImpl<CsvRowError>(this as CsvRowError, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvRowError;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvRowError&&(identical(other.lineNumber, _this.lineNumber) || other.lineNumber == _this.lineNumber)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.currencyCode, _this.currencyCode) || other.currencyCode == _this.currencyCode));
}


@override
int get hashCode {
  final _this = this as CsvRowError;
  return Object.hash(runtimeType,_this.lineNumber,_this.reason,_this.currencyCode);
}

@override
String toString() {
  final _this = this as CsvRowError;
  return 'CsvRowError(lineNumber: ${_this.lineNumber}, reason: ${_this.reason}, currencyCode: ${_this.currencyCode})';
}


}

/// @nodoc
abstract mixin class $CsvRowErrorCopyWith<$Res>  {
  factory $CsvRowErrorCopyWith(CsvRowError value, $Res Function(CsvRowError) _then) = _$CsvRowErrorCopyWithImpl;
@useResult
$Res call({
 int lineNumber, CsvRowErrorReason reason, String? currencyCode
});




}
/// @nodoc
class _$CsvRowErrorCopyWithImpl<$Res>
    implements $CsvRowErrorCopyWith<$Res> {
  _$CsvRowErrorCopyWithImpl(this._self, this._then);

  final CsvRowError _self;
  final $Res Function(CsvRowError) _then;

/// Create a copy of CsvRowError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lineNumber = null,Object? reason = null,Object? currencyCode = freezed,}) {
  return _then(CsvRowError(
lineNumber: null == lineNumber ? _self.lineNumber : lineNumber // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CsvRowErrorReason,currencyCode: freezed == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CsvRowError].
extension CsvRowErrorPatterns on CsvRowError {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvRowError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvRowError() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvRowError value)  $default,){
final _that = this;
switch (_that) {
case _CsvRowError():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvRowError value)?  $default,){
final _that = this;
switch (_that) {
case _CsvRowError() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int lineNumber,  CsvRowErrorReason reason,  String? currencyCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvRowError() when $default != null:
return $default(_that.lineNumber,_that.reason,_that.currencyCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int lineNumber,  CsvRowErrorReason reason,  String? currencyCode)  $default,) {final _that = this;
switch (_that) {
case _CsvRowError():
return $default(_that.lineNumber,_that.reason,_that.currencyCode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int lineNumber,  CsvRowErrorReason reason,  String? currencyCode)?  $default,) {final _that = this;
switch (_that) {
case _CsvRowError() when $default != null:
return $default(_that.lineNumber,_that.reason,_that.currencyCode);case _:
  return null;

}
}

}

/// @nodoc


class _CsvRowError implements CsvRowError {
  const _CsvRowError({required this.lineNumber, required this.reason, this.currencyCode});
  

/// 1-based physical line in the file; the header is line 1.
@override final  int lineNumber;
@override final  CsvRowErrorReason reason;
/// The unknown code, for [CsvRowErrorReason.unknownCurrency]; null
/// otherwise.
@override final  String? currencyCode;

/// Create a copy of CsvRowError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvRowErrorCopyWith<_CsvRowError> get copyWith => __$CsvRowErrorCopyWithImpl<_CsvRowError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvRowError&&(identical(other.lineNumber, lineNumber) || other.lineNumber == lineNumber)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,lineNumber,reason,currencyCode);
}

@override
String toString() {
    return 'CsvRowError(lineNumber: $lineNumber, reason: $reason, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class _$CsvRowErrorCopyWith<$Res> implements $CsvRowErrorCopyWith<$Res> {
  factory _$CsvRowErrorCopyWith(_CsvRowError value, $Res Function(_CsvRowError) _then) = __$CsvRowErrorCopyWithImpl;
@override @useResult
$Res call({
 int lineNumber, CsvRowErrorReason reason, String? currencyCode
});




}
/// @nodoc
class __$CsvRowErrorCopyWithImpl<$Res>
    implements _$CsvRowErrorCopyWith<$Res> {
  __$CsvRowErrorCopyWithImpl(this._self, this._then);

  final _CsvRowError _self;
  final $Res Function(_CsvRowError) _then;

/// Create a copy of CsvRowError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lineNumber = null,Object? reason = null,Object? currencyCode = freezed,}) {
  return _then(_CsvRowError(
lineNumber: null == lineNumber ? _self.lineNumber : lineNumber // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CsvRowErrorReason,currencyCode: freezed == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ParsedCsvRow {

/// 1-based physical line where the row starts.
 int get line;/// Trimmed, non-empty.
 String get account;/// Trimmed, non-empty.
 String get category;/// Trimmed, unvalidated amount text.
 String get amountText;/// Trimmed and upper-cased, unvalidated currency code.
 String get currencyCode;/// Recorded At as device-local time.
 DateTime get recordedAt;/// The note verbatim, or null when it is missing or blank.
 String? get memo;
/// Create a copy of ParsedCsvRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedCsvRowCopyWith<ParsedCsvRow> get copyWith => _$ParsedCsvRowCopyWithImpl<ParsedCsvRow>(this as ParsedCsvRow, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ParsedCsvRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedCsvRow&&(identical(other.line, _this.line) || other.line == _this.line)&&(identical(other.account, _this.account) || other.account == _this.account)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.amountText, _this.amountText) || other.amountText == _this.amountText)&&(identical(other.currencyCode, _this.currencyCode) || other.currencyCode == _this.currencyCode)&&(identical(other.recordedAt, _this.recordedAt) || other.recordedAt == _this.recordedAt)&&(identical(other.memo, _this.memo) || other.memo == _this.memo));
}


@override
int get hashCode {
  final _this = this as ParsedCsvRow;
  return Object.hash(runtimeType,_this.line,_this.account,_this.category,_this.amountText,_this.currencyCode,_this.recordedAt,_this.memo);
}

@override
String toString() {
  final _this = this as ParsedCsvRow;
  return 'ParsedCsvRow(line: ${_this.line}, account: ${_this.account}, category: ${_this.category}, amountText: ${_this.amountText}, currencyCode: ${_this.currencyCode}, recordedAt: ${_this.recordedAt}, memo: ${_this.memo})';
}


}

/// @nodoc
abstract mixin class $ParsedCsvRowCopyWith<$Res>  {
  factory $ParsedCsvRowCopyWith(ParsedCsvRow value, $Res Function(ParsedCsvRow) _then) = _$ParsedCsvRowCopyWithImpl;
@useResult
$Res call({
 int line, String account, String category, String amountText, String currencyCode, DateTime recordedAt, String? memo
});




}
/// @nodoc
class _$ParsedCsvRowCopyWithImpl<$Res>
    implements $ParsedCsvRowCopyWith<$Res> {
  _$ParsedCsvRowCopyWithImpl(this._self, this._then);

  final ParsedCsvRow _self;
  final $Res Function(ParsedCsvRow) _then;

/// Create a copy of ParsedCsvRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? line = null,Object? account = null,Object? category = null,Object? amountText = null,Object? currencyCode = null,Object? recordedAt = null,Object? memo = freezed,}) {
  return _then(ParsedCsvRow(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amountText: null == amountText ? _self.amountText : amountText // ignore: cast_nullable_to_non_nullable
as String,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedCsvRow].
extension ParsedCsvRowPatterns on ParsedCsvRow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedCsvRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedCsvRow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedCsvRow value)  $default,){
final _that = this;
switch (_that) {
case _ParsedCsvRow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedCsvRow value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedCsvRow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int line,  String account,  String category,  String amountText,  String currencyCode,  DateTime recordedAt,  String? memo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedCsvRow() when $default != null:
return $default(_that.line,_that.account,_that.category,_that.amountText,_that.currencyCode,_that.recordedAt,_that.memo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int line,  String account,  String category,  String amountText,  String currencyCode,  DateTime recordedAt,  String? memo)  $default,) {final _that = this;
switch (_that) {
case _ParsedCsvRow():
return $default(_that.line,_that.account,_that.category,_that.amountText,_that.currencyCode,_that.recordedAt,_that.memo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int line,  String account,  String category,  String amountText,  String currencyCode,  DateTime recordedAt,  String? memo)?  $default,) {final _that = this;
switch (_that) {
case _ParsedCsvRow() when $default != null:
return $default(_that.line,_that.account,_that.category,_that.amountText,_that.currencyCode,_that.recordedAt,_that.memo);case _:
  return null;

}
}

}

/// @nodoc


class _ParsedCsvRow implements ParsedCsvRow {
  const _ParsedCsvRow({required this.line, required this.account, required this.category, required this.amountText, required this.currencyCode, required this.recordedAt, this.memo});
  

/// 1-based physical line where the row starts.
@override final  int line;
/// Trimmed, non-empty.
@override final  String account;
/// Trimmed, non-empty.
@override final  String category;
/// Trimmed, unvalidated amount text.
@override final  String amountText;
/// Trimmed and upper-cased, unvalidated currency code.
@override final  String currencyCode;
/// Recorded At as device-local time.
@override final  DateTime recordedAt;
/// The note verbatim, or null when it is missing or blank.
@override final  String? memo;

/// Create a copy of ParsedCsvRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedCsvRowCopyWith<_ParsedCsvRow> get copyWith => __$ParsedCsvRowCopyWithImpl<_ParsedCsvRow>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedCsvRow&&(identical(other.line, line) || other.line == line)&&(identical(other.account, account) || other.account == account)&&(identical(other.category, category) || other.category == category)&&(identical(other.amountText, amountText) || other.amountText == amountText)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.memo, memo) || other.memo == memo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,line,account,category,amountText,currencyCode,recordedAt,memo);
}

@override
String toString() {
    return 'ParsedCsvRow(line: $line, account: $account, category: $category, amountText: $amountText, currencyCode: $currencyCode, recordedAt: $recordedAt, memo: $memo)';
}


}

/// @nodoc
abstract mixin class _$ParsedCsvRowCopyWith<$Res> implements $ParsedCsvRowCopyWith<$Res> {
  factory _$ParsedCsvRowCopyWith(_ParsedCsvRow value, $Res Function(_ParsedCsvRow) _then) = __$ParsedCsvRowCopyWithImpl;
@override @useResult
$Res call({
 int line, String account, String category, String amountText, String currencyCode, DateTime recordedAt, String? memo
});




}
/// @nodoc
class __$ParsedCsvRowCopyWithImpl<$Res>
    implements _$ParsedCsvRowCopyWith<$Res> {
  __$ParsedCsvRowCopyWithImpl(this._self, this._then);

  final _ParsedCsvRow _self;
  final $Res Function(_ParsedCsvRow) _then;

/// Create a copy of ParsedCsvRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? line = null,Object? account = null,Object? category = null,Object? amountText = null,Object? currencyCode = null,Object? recordedAt = null,Object? memo = freezed,}) {
  return _then(_ParsedCsvRow(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amountText: null == amountText ? _self.amountText : amountText // ignore: cast_nullable_to_non_nullable
as String,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$FortuneCityCsvParseResult {

 List<ParsedCsvRow> get rows; List<CsvRowError> get errors;
/// Create a copy of FortuneCityCsvParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FortuneCityCsvParseResultCopyWith<FortuneCityCsvParseResult> get copyWith => _$FortuneCityCsvParseResultCopyWithImpl<FortuneCityCsvParseResult>(this as FortuneCityCsvParseResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FortuneCityCsvParseResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FortuneCityCsvParseResult&&const DeepCollectionEquality().equals(other.rows, _this.rows)&&const DeepCollectionEquality().equals(other.errors, _this.errors));
}


@override
int get hashCode {
  final _this = this as FortuneCityCsvParseResult;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.rows),const DeepCollectionEquality().hash(_this.errors));
}

@override
String toString() {
  final _this = this as FortuneCityCsvParseResult;
  return 'FortuneCityCsvParseResult(rows: ${_this.rows}, errors: ${_this.errors})';
}


}

/// @nodoc
abstract mixin class $FortuneCityCsvParseResultCopyWith<$Res>  {
  factory $FortuneCityCsvParseResultCopyWith(FortuneCityCsvParseResult value, $Res Function(FortuneCityCsvParseResult) _then) = _$FortuneCityCsvParseResultCopyWithImpl;
@useResult
$Res call({
 List<ParsedCsvRow> rows, List<CsvRowError> errors
});




}
/// @nodoc
class _$FortuneCityCsvParseResultCopyWithImpl<$Res>
    implements $FortuneCityCsvParseResultCopyWith<$Res> {
  _$FortuneCityCsvParseResultCopyWithImpl(this._self, this._then);

  final FortuneCityCsvParseResult _self;
  final $Res Function(FortuneCityCsvParseResult) _then;

/// Create a copy of FortuneCityCsvParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? errors = null,}) {
  return _then(FortuneCityCsvParseResult(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<ParsedCsvRow>,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<CsvRowError>,
  ));
}

}


/// Adds pattern-matching-related methods to [FortuneCityCsvParseResult].
extension FortuneCityCsvParseResultPatterns on FortuneCityCsvParseResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FortuneCityCsvParseResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FortuneCityCsvParseResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FortuneCityCsvParseResult value)  $default,){
final _that = this;
switch (_that) {
case _FortuneCityCsvParseResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FortuneCityCsvParseResult value)?  $default,){
final _that = this;
switch (_that) {
case _FortuneCityCsvParseResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ParsedCsvRow> rows,  List<CsvRowError> errors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FortuneCityCsvParseResult() when $default != null:
return $default(_that.rows,_that.errors);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ParsedCsvRow> rows,  List<CsvRowError> errors)  $default,) {final _that = this;
switch (_that) {
case _FortuneCityCsvParseResult():
return $default(_that.rows,_that.errors);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ParsedCsvRow> rows,  List<CsvRowError> errors)?  $default,) {final _that = this;
switch (_that) {
case _FortuneCityCsvParseResult() when $default != null:
return $default(_that.rows,_that.errors);case _:
  return null;

}
}

}

/// @nodoc


class _FortuneCityCsvParseResult implements FortuneCityCsvParseResult {
  const _FortuneCityCsvParseResult({required  List<ParsedCsvRow> rows, required  List<CsvRowError> errors}): _rows = rows,_errors = errors;
  

 final  List<ParsedCsvRow> _rows;
@override List<ParsedCsvRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  List<CsvRowError> _errors;
@override List<CsvRowError> get errors {
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errors);
}


/// Create a copy of FortuneCityCsvParseResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FortuneCityCsvParseResultCopyWith<_FortuneCityCsvParseResult> get copyWith => __$FortuneCityCsvParseResultCopyWithImpl<_FortuneCityCsvParseResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FortuneCityCsvParseResult&&const DeepCollectionEquality().equals(other.rows, _rows)&&const DeepCollectionEquality().equals(other.errors, _errors));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_errors));
}

@override
String toString() {
    return 'FortuneCityCsvParseResult(rows: $rows, errors: $errors)';
}


}

/// @nodoc
abstract mixin class _$FortuneCityCsvParseResultCopyWith<$Res> implements $FortuneCityCsvParseResultCopyWith<$Res> {
  factory _$FortuneCityCsvParseResultCopyWith(_FortuneCityCsvParseResult value, $Res Function(_FortuneCityCsvParseResult) _then) = __$FortuneCityCsvParseResultCopyWithImpl;
@override @useResult
$Res call({
 List<ParsedCsvRow> rows, List<CsvRowError> errors
});




}
/// @nodoc
class __$FortuneCityCsvParseResultCopyWithImpl<$Res>
    implements _$FortuneCityCsvParseResultCopyWith<$Res> {
  __$FortuneCityCsvParseResultCopyWithImpl(this._self, this._then);

  final _FortuneCityCsvParseResult _self;
  final $Res Function(_FortuneCityCsvParseResult) _then;

/// Create a copy of FortuneCityCsvParseResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? errors = null,}) {
  return _then(_FortuneCityCsvParseResult(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<ParsedCsvRow>,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<CsvRowError>,
  ));
}


}

/// @nodoc
mixin _$CsvImportRow {

/// 1-based physical line where the row starts.
 int get line;/// Trimmed CSV Account value; keys [CsvImportPlan.accounts].
 String get account;/// Trimmed CSV Category value; keys [CsvImportPlan.categories].
 String get category;/// Rounded half-up, always > 0.
 int get amountMinorUnits; Currency get currency;/// Recorded At as device-local time. Becomes `createdAt`; its day
/// becomes `date`.
 DateTime get recordedAt; String? get memo;
/// Create a copy of CsvImportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvImportRowCopyWith<CsvImportRow> get copyWith => _$CsvImportRowCopyWithImpl<CsvImportRow>(this as CsvImportRow, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvImportRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportRow&&(identical(other.line, _this.line) || other.line == _this.line)&&(identical(other.account, _this.account) || other.account == _this.account)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.amountMinorUnits, _this.amountMinorUnits) || other.amountMinorUnits == _this.amountMinorUnits)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.recordedAt, _this.recordedAt) || other.recordedAt == _this.recordedAt)&&(identical(other.memo, _this.memo) || other.memo == _this.memo));
}


@override
int get hashCode {
  final _this = this as CsvImportRow;
  return Object.hash(runtimeType,_this.line,_this.account,_this.category,_this.amountMinorUnits,_this.currency,_this.recordedAt,_this.memo);
}

@override
String toString() {
  final _this = this as CsvImportRow;
  return 'CsvImportRow(line: ${_this.line}, account: ${_this.account}, category: ${_this.category}, amountMinorUnits: ${_this.amountMinorUnits}, currency: ${_this.currency}, recordedAt: ${_this.recordedAt}, memo: ${_this.memo})';
}


}

/// @nodoc
abstract mixin class $CsvImportRowCopyWith<$Res>  {
  factory $CsvImportRowCopyWith(CsvImportRow value, $Res Function(CsvImportRow) _then) = _$CsvImportRowCopyWithImpl;
@useResult
$Res call({
 int line, String account, String category, int amountMinorUnits, Currency currency, DateTime recordedAt, String? memo
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$CsvImportRowCopyWithImpl<$Res>
    implements $CsvImportRowCopyWith<$Res> {
  _$CsvImportRowCopyWithImpl(this._self, this._then);

  final CsvImportRow _self;
  final $Res Function(CsvImportRow) _then;

/// Create a copy of CsvImportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? line = null,Object? account = null,Object? category = null,Object? amountMinorUnits = null,Object? currency = null,Object? recordedAt = null,Object? memo = freezed,}) {
  return _then(CsvImportRow(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CsvImportRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [CsvImportRow].
extension CsvImportRowPatterns on CsvImportRow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvImportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvImportRow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvImportRow value)  $default,){
final _that = this;
switch (_that) {
case _CsvImportRow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvImportRow value)?  $default,){
final _that = this;
switch (_that) {
case _CsvImportRow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int line,  String account,  String category,  int amountMinorUnits,  Currency currency,  DateTime recordedAt,  String? memo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvImportRow() when $default != null:
return $default(_that.line,_that.account,_that.category,_that.amountMinorUnits,_that.currency,_that.recordedAt,_that.memo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int line,  String account,  String category,  int amountMinorUnits,  Currency currency,  DateTime recordedAt,  String? memo)  $default,) {final _that = this;
switch (_that) {
case _CsvImportRow():
return $default(_that.line,_that.account,_that.category,_that.amountMinorUnits,_that.currency,_that.recordedAt,_that.memo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int line,  String account,  String category,  int amountMinorUnits,  Currency currency,  DateTime recordedAt,  String? memo)?  $default,) {final _that = this;
switch (_that) {
case _CsvImportRow() when $default != null:
return $default(_that.line,_that.account,_that.category,_that.amountMinorUnits,_that.currency,_that.recordedAt,_that.memo);case _:
  return null;

}
}

}

/// @nodoc


class _CsvImportRow implements CsvImportRow {
  const _CsvImportRow({required this.line, required this.account, required this.category, required this.amountMinorUnits, required this.currency, required this.recordedAt, this.memo});
  

/// 1-based physical line where the row starts.
@override final  int line;
/// Trimmed CSV Account value; keys [CsvImportPlan.accounts].
@override final  String account;
/// Trimmed CSV Category value; keys [CsvImportPlan.categories].
@override final  String category;
/// Rounded half-up, always > 0.
@override final  int amountMinorUnits;
@override final  Currency currency;
/// Recorded At as device-local time. Becomes `createdAt`; its day
/// becomes `date`.
@override final  DateTime recordedAt;
@override final  String? memo;

/// Create a copy of CsvImportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvImportRowCopyWith<_CsvImportRow> get copyWith => __$CsvImportRowCopyWithImpl<_CsvImportRow>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvImportRow&&(identical(other.line, line) || other.line == line)&&(identical(other.account, account) || other.account == account)&&(identical(other.category, category) || other.category == category)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.memo, memo) || other.memo == memo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,line,account,category,amountMinorUnits,currency,recordedAt,memo);
}

@override
String toString() {
    return 'CsvImportRow(line: $line, account: $account, category: $category, amountMinorUnits: $amountMinorUnits, currency: $currency, recordedAt: $recordedAt, memo: $memo)';
}


}

/// @nodoc
abstract mixin class _$CsvImportRowCopyWith<$Res> implements $CsvImportRowCopyWith<$Res> {
  factory _$CsvImportRowCopyWith(_CsvImportRow value, $Res Function(_CsvImportRow) _then) = __$CsvImportRowCopyWithImpl;
@override @useResult
$Res call({
 int line, String account, String category, int amountMinorUnits, Currency currency, DateTime recordedAt, String? memo
});


@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$CsvImportRowCopyWithImpl<$Res>
    implements _$CsvImportRowCopyWith<$Res> {
  __$CsvImportRowCopyWithImpl(this._self, this._then);

  final _CsvImportRow _self;
  final $Res Function(_CsvImportRow) _then;

/// Create a copy of CsvImportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? line = null,Object? account = null,Object? category = null,Object? amountMinorUnits = null,Object? currency = null,Object? recordedAt = null,Object? memo = freezed,}) {
  return _then(_CsvImportRow(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CsvImportRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}

/// @nodoc
mixin _$CsvLoadResult {

 String get fileName;/// Every valid row in file order, duplicates included. Becomes
/// [CsvImportPlan.rows], so the commit can recount duplicates.
 List<CsvImportRow> get validRows;/// The valid rows not already in the database. Matching and the
/// preview use these.
 List<CsvImportRow> get rowsToImport;/// `validRows.length - rowsToImport.length`.
 int get duplicateCount;/// Skipped rows, sorted by line.
 List<CsvRowError> get errors;
/// Create a copy of CsvLoadResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvLoadResultCopyWith<CsvLoadResult> get copyWith => _$CsvLoadResultCopyWithImpl<CsvLoadResult>(this as CsvLoadResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvLoadResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvLoadResult&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&const DeepCollectionEquality().equals(other.validRows, _this.validRows)&&const DeepCollectionEquality().equals(other.rowsToImport, _this.rowsToImport)&&(identical(other.duplicateCount, _this.duplicateCount) || other.duplicateCount == _this.duplicateCount)&&const DeepCollectionEquality().equals(other.errors, _this.errors));
}


@override
int get hashCode {
  final _this = this as CsvLoadResult;
  return Object.hash(runtimeType,_this.fileName,const DeepCollectionEquality().hash(_this.validRows),const DeepCollectionEquality().hash(_this.rowsToImport),_this.duplicateCount,const DeepCollectionEquality().hash(_this.errors));
}

@override
String toString() {
  final _this = this as CsvLoadResult;
  return 'CsvLoadResult(fileName: ${_this.fileName}, validRows: ${_this.validRows}, rowsToImport: ${_this.rowsToImport}, duplicateCount: ${_this.duplicateCount}, errors: ${_this.errors})';
}


}

/// @nodoc
abstract mixin class $CsvLoadResultCopyWith<$Res>  {
  factory $CsvLoadResultCopyWith(CsvLoadResult value, $Res Function(CsvLoadResult) _then) = _$CsvLoadResultCopyWithImpl;
@useResult
$Res call({
 String fileName, List<CsvImportRow> validRows, List<CsvImportRow> rowsToImport, int duplicateCount, List<CsvRowError> errors
});




}
/// @nodoc
class _$CsvLoadResultCopyWithImpl<$Res>
    implements $CsvLoadResultCopyWith<$Res> {
  _$CsvLoadResultCopyWithImpl(this._self, this._then);

  final CsvLoadResult _self;
  final $Res Function(CsvLoadResult) _then;

/// Create a copy of CsvLoadResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? validRows = null,Object? rowsToImport = null,Object? duplicateCount = null,Object? errors = null,}) {
  return _then(CsvLoadResult(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,validRows: null == validRows ? _self.validRows : validRows // ignore: cast_nullable_to_non_nullable
as List<CsvImportRow>,rowsToImport: null == rowsToImport ? _self.rowsToImport : rowsToImport // ignore: cast_nullable_to_non_nullable
as List<CsvImportRow>,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<CsvRowError>,
  ));
}

}


/// Adds pattern-matching-related methods to [CsvLoadResult].
extension CsvLoadResultPatterns on CsvLoadResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvLoadResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvLoadResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvLoadResult value)  $default,){
final _that = this;
switch (_that) {
case _CsvLoadResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvLoadResult value)?  $default,){
final _that = this;
switch (_that) {
case _CsvLoadResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  List<CsvImportRow> validRows,  List<CsvImportRow> rowsToImport,  int duplicateCount,  List<CsvRowError> errors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvLoadResult() when $default != null:
return $default(_that.fileName,_that.validRows,_that.rowsToImport,_that.duplicateCount,_that.errors);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  List<CsvImportRow> validRows,  List<CsvImportRow> rowsToImport,  int duplicateCount,  List<CsvRowError> errors)  $default,) {final _that = this;
switch (_that) {
case _CsvLoadResult():
return $default(_that.fileName,_that.validRows,_that.rowsToImport,_that.duplicateCount,_that.errors);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  List<CsvImportRow> validRows,  List<CsvImportRow> rowsToImport,  int duplicateCount,  List<CsvRowError> errors)?  $default,) {final _that = this;
switch (_that) {
case _CsvLoadResult() when $default != null:
return $default(_that.fileName,_that.validRows,_that.rowsToImport,_that.duplicateCount,_that.errors);case _:
  return null;

}
}

}

/// @nodoc


class _CsvLoadResult implements CsvLoadResult {
  const _CsvLoadResult({required this.fileName, required  List<CsvImportRow> validRows, required  List<CsvImportRow> rowsToImport, required this.duplicateCount, required  List<CsvRowError> errors}): _validRows = validRows,_rowsToImport = rowsToImport,_errors = errors;
  

@override final  String fileName;
/// Every valid row in file order, duplicates included. Becomes
/// [CsvImportPlan.rows], so the commit can recount duplicates.
 final  List<CsvImportRow> _validRows;
/// Every valid row in file order, duplicates included. Becomes
/// [CsvImportPlan.rows], so the commit can recount duplicates.
@override List<CsvImportRow> get validRows {
  if (_validRows is EqualUnmodifiableListView) return _validRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_validRows);
}

/// The valid rows not already in the database. Matching and the
/// preview use these.
 final  List<CsvImportRow> _rowsToImport;
/// The valid rows not already in the database. Matching and the
/// preview use these.
@override List<CsvImportRow> get rowsToImport {
  if (_rowsToImport is EqualUnmodifiableListView) return _rowsToImport;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rowsToImport);
}

/// `validRows.length - rowsToImport.length`.
@override final  int duplicateCount;
/// Skipped rows, sorted by line.
 final  List<CsvRowError> _errors;
/// Skipped rows, sorted by line.
@override List<CsvRowError> get errors {
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errors);
}


/// Create a copy of CsvLoadResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvLoadResultCopyWith<_CsvLoadResult> get copyWith => __$CsvLoadResultCopyWithImpl<_CsvLoadResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvLoadResult&&(identical(other.fileName, fileName) || other.fileName == fileName)&&const DeepCollectionEquality().equals(other.validRows, _validRows)&&const DeepCollectionEquality().equals(other.rowsToImport, _rowsToImport)&&(identical(other.duplicateCount, duplicateCount) || other.duplicateCount == duplicateCount)&&const DeepCollectionEquality().equals(other.errors, _errors));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fileName,const DeepCollectionEquality().hash(_validRows),const DeepCollectionEquality().hash(_rowsToImport),duplicateCount,const DeepCollectionEquality().hash(_errors));
}

@override
String toString() {
    return 'CsvLoadResult(fileName: $fileName, validRows: $validRows, rowsToImport: $rowsToImport, duplicateCount: $duplicateCount, errors: $errors)';
}


}

/// @nodoc
abstract mixin class _$CsvLoadResultCopyWith<$Res> implements $CsvLoadResultCopyWith<$Res> {
  factory _$CsvLoadResultCopyWith(_CsvLoadResult value, $Res Function(_CsvLoadResult) _then) = __$CsvLoadResultCopyWithImpl;
@override @useResult
$Res call({
 String fileName, List<CsvImportRow> validRows, List<CsvImportRow> rowsToImport, int duplicateCount, List<CsvRowError> errors
});




}
/// @nodoc
class __$CsvLoadResultCopyWithImpl<$Res>
    implements _$CsvLoadResultCopyWith<$Res> {
  __$CsvLoadResultCopyWithImpl(this._self, this._then);

  final _CsvLoadResult _self;
  final $Res Function(_CsvLoadResult) _then;

/// Create a copy of CsvLoadResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? validRows = null,Object? rowsToImport = null,Object? duplicateCount = null,Object? errors = null,}) {
  return _then(_CsvLoadResult(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,validRows: null == validRows ? _self._validRows : validRows // ignore: cast_nullable_to_non_nullable
as List<CsvImportRow>,rowsToImport: null == rowsToImport ? _self._rowsToImport : rowsToImport // ignore: cast_nullable_to_non_nullable
as List<CsvImportRow>,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<CsvRowError>,
  ));
}


}

/// @nodoc
mixin _$AccountResolution {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountResolution);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountResolution()';
}


}

/// @nodoc
class $AccountResolutionCopyWith<$Res>  {
$AccountResolutionCopyWith(AccountResolution _, $Res Function(AccountResolution) __);
}


/// Adds pattern-matching-related methods to [AccountResolution].
extension AccountResolutionPatterns on AccountResolution {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExistingAccountResolution value)?  existing,TResult Function( CreateAccountResolution value)?  createAccount,TResult Function( CreateTypeAndAccountResolution value)?  createTypeAndAccount,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExistingAccountResolution() when existing != null:
return existing(_that);case CreateAccountResolution() when createAccount != null:
return createAccount(_that);case CreateTypeAndAccountResolution() when createTypeAndAccount != null:
return createTypeAndAccount(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExistingAccountResolution value)  existing,required TResult Function( CreateAccountResolution value)  createAccount,required TResult Function( CreateTypeAndAccountResolution value)  createTypeAndAccount,}){
final _that = this;
switch (_that) {
case ExistingAccountResolution():
return existing(_that);case CreateAccountResolution():
return createAccount(_that);case CreateTypeAndAccountResolution():
return createTypeAndAccount(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExistingAccountResolution value)?  existing,TResult? Function( CreateAccountResolution value)?  createAccount,TResult? Function( CreateTypeAndAccountResolution value)?  createTypeAndAccount,}){
final _that = this;
switch (_that) {
case ExistingAccountResolution() when existing != null:
return existing(_that);case CreateAccountResolution() when createAccount != null:
return createAccount(_that);case CreateTypeAndAccountResolution() when createTypeAndAccount != null:
return createTypeAndAccount(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int accountId)?  existing,TResult Function( String name,  int accountTypeId,  String currencyCode)?  createAccount,TResult Function( String name,  String currencyCode)?  createTypeAndAccount,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExistingAccountResolution() when existing != null:
return existing(_that.accountId);case CreateAccountResolution() when createAccount != null:
return createAccount(_that.name,_that.accountTypeId,_that.currencyCode);case CreateTypeAndAccountResolution() when createTypeAndAccount != null:
return createTypeAndAccount(_that.name,_that.currencyCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int accountId)  existing,required TResult Function( String name,  int accountTypeId,  String currencyCode)  createAccount,required TResult Function( String name,  String currencyCode)  createTypeAndAccount,}) {final _that = this;
switch (_that) {
case ExistingAccountResolution():
return existing(_that.accountId);case CreateAccountResolution():
return createAccount(_that.name,_that.accountTypeId,_that.currencyCode);case CreateTypeAndAccountResolution():
return createTypeAndAccount(_that.name,_that.currencyCode);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int accountId)?  existing,TResult? Function( String name,  int accountTypeId,  String currencyCode)?  createAccount,TResult? Function( String name,  String currencyCode)?  createTypeAndAccount,}) {final _that = this;
switch (_that) {
case ExistingAccountResolution() when existing != null:
return existing(_that.accountId);case CreateAccountResolution() when createAccount != null:
return createAccount(_that.name,_that.accountTypeId,_that.currencyCode);case CreateTypeAndAccountResolution() when createTypeAndAccount != null:
return createTypeAndAccount(_that.name,_that.currencyCode);case _:
  return null;

}
}

}

/// @nodoc


class ExistingAccountResolution implements AccountResolution {
  const ExistingAccountResolution(this.accountId);
  

 final  int accountId;

/// Create a copy of AccountResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExistingAccountResolutionCopyWith<ExistingAccountResolution> get copyWith => _$ExistingAccountResolutionCopyWithImpl<ExistingAccountResolution>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExistingAccountResolution&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accountId);
}

@override
String toString() {
    return 'AccountResolution.existing(accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $ExistingAccountResolutionCopyWith<$Res> implements $AccountResolutionCopyWith<$Res> {
  factory $ExistingAccountResolutionCopyWith(ExistingAccountResolution value, $Res Function(ExistingAccountResolution) _then) = _$ExistingAccountResolutionCopyWithImpl;
@useResult
$Res call({
 int accountId
});




}
/// @nodoc
class _$ExistingAccountResolutionCopyWithImpl<$Res>
    implements $ExistingAccountResolutionCopyWith<$Res> {
  _$ExistingAccountResolutionCopyWithImpl(this._self, this._then);

  final ExistingAccountResolution _self;
  final $Res Function(ExistingAccountResolution) _then;

/// Create a copy of AccountResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accountId = null,}) {
  return _then(ExistingAccountResolution(
null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CreateAccountResolution implements AccountResolution {
  const CreateAccountResolution({required this.name, required this.accountTypeId, required this.currencyCode});
  

 final  String name;
 final  int accountTypeId;
 final  String currencyCode;

/// Create a copy of AccountResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateAccountResolutionCopyWith<CreateAccountResolution> get copyWith => _$CreateAccountResolutionCopyWithImpl<CreateAccountResolution>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateAccountResolution&&(identical(other.name, name) || other.name == name)&&(identical(other.accountTypeId, accountTypeId) || other.accountTypeId == accountTypeId)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,accountTypeId,currencyCode);
}

@override
String toString() {
    return 'AccountResolution.createAccount(name: $name, accountTypeId: $accountTypeId, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class $CreateAccountResolutionCopyWith<$Res> implements $AccountResolutionCopyWith<$Res> {
  factory $CreateAccountResolutionCopyWith(CreateAccountResolution value, $Res Function(CreateAccountResolution) _then) = _$CreateAccountResolutionCopyWithImpl;
@useResult
$Res call({
 String name, int accountTypeId, String currencyCode
});




}
/// @nodoc
class _$CreateAccountResolutionCopyWithImpl<$Res>
    implements $CreateAccountResolutionCopyWith<$Res> {
  _$CreateAccountResolutionCopyWithImpl(this._self, this._then);

  final CreateAccountResolution _self;
  final $Res Function(CreateAccountResolution) _then;

/// Create a copy of AccountResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? accountTypeId = null,Object? currencyCode = null,}) {
  return _then(CreateAccountResolution(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,accountTypeId: null == accountTypeId ? _self.accountTypeId : accountTypeId // ignore: cast_nullable_to_non_nullable
as int,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CreateTypeAndAccountResolution implements AccountResolution {
  const CreateTypeAndAccountResolution({required this.name, required this.currencyCode});
  

 final  String name;
 final  String currencyCode;

/// Create a copy of AccountResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTypeAndAccountResolutionCopyWith<CreateTypeAndAccountResolution> get copyWith => _$CreateTypeAndAccountResolutionCopyWithImpl<CreateTypeAndAccountResolution>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTypeAndAccountResolution&&(identical(other.name, name) || other.name == name)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,currencyCode);
}

@override
String toString() {
    return 'AccountResolution.createTypeAndAccount(name: $name, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class $CreateTypeAndAccountResolutionCopyWith<$Res> implements $AccountResolutionCopyWith<$Res> {
  factory $CreateTypeAndAccountResolutionCopyWith(CreateTypeAndAccountResolution value, $Res Function(CreateTypeAndAccountResolution) _then) = _$CreateTypeAndAccountResolutionCopyWithImpl;
@useResult
$Res call({
 String name, String currencyCode
});




}
/// @nodoc
class _$CreateTypeAndAccountResolutionCopyWithImpl<$Res>
    implements $CreateTypeAndAccountResolutionCopyWith<$Res> {
  _$CreateTypeAndAccountResolutionCopyWithImpl(this._self, this._then);

  final CreateTypeAndAccountResolution _self;
  final $Res Function(CreateTypeAndAccountResolution) _then;

/// Create a copy of AccountResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? currencyCode = null,}) {
  return _then(CreateTypeAndAccountResolution(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CategoryResolution {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryResolution);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CategoryResolution()';
}


}

/// @nodoc
class $CategoryResolutionCopyWith<$Res>  {
$CategoryResolutionCopyWith(CategoryResolution _, $Res Function(CategoryResolution) __);
}


/// Adds pattern-matching-related methods to [CategoryResolution].
extension CategoryResolutionPatterns on CategoryResolution {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExistingCategoryResolution value)?  existing,TResult Function( CreateCategoryResolution value)?  create,TResult Function( IncomeByNoteCategoryResolution value)?  incomeByNote,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExistingCategoryResolution() when existing != null:
return existing(_that);case CreateCategoryResolution() when create != null:
return create(_that);case IncomeByNoteCategoryResolution() when incomeByNote != null:
return incomeByNote(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExistingCategoryResolution value)  existing,required TResult Function( CreateCategoryResolution value)  create,required TResult Function( IncomeByNoteCategoryResolution value)  incomeByNote,}){
final _that = this;
switch (_that) {
case ExistingCategoryResolution():
return existing(_that);case CreateCategoryResolution():
return create(_that);case IncomeByNoteCategoryResolution():
return incomeByNote(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExistingCategoryResolution value)?  existing,TResult? Function( CreateCategoryResolution value)?  create,TResult? Function( IncomeByNoteCategoryResolution value)?  incomeByNote,}){
final _that = this;
switch (_that) {
case ExistingCategoryResolution() when existing != null:
return existing(_that);case CreateCategoryResolution() when create != null:
return create(_that);case IncomeByNoteCategoryResolution() when incomeByNote != null:
return incomeByNote(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int categoryId)?  existing,TResult Function( String name,  CategoryType type)?  create,TResult Function( int salaryCategoryId,  int otherCategoryId)?  incomeByNote,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExistingCategoryResolution() when existing != null:
return existing(_that.categoryId);case CreateCategoryResolution() when create != null:
return create(_that.name,_that.type);case IncomeByNoteCategoryResolution() when incomeByNote != null:
return incomeByNote(_that.salaryCategoryId,_that.otherCategoryId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int categoryId)  existing,required TResult Function( String name,  CategoryType type)  create,required TResult Function( int salaryCategoryId,  int otherCategoryId)  incomeByNote,}) {final _that = this;
switch (_that) {
case ExistingCategoryResolution():
return existing(_that.categoryId);case CreateCategoryResolution():
return create(_that.name,_that.type);case IncomeByNoteCategoryResolution():
return incomeByNote(_that.salaryCategoryId,_that.otherCategoryId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int categoryId)?  existing,TResult? Function( String name,  CategoryType type)?  create,TResult? Function( int salaryCategoryId,  int otherCategoryId)?  incomeByNote,}) {final _that = this;
switch (_that) {
case ExistingCategoryResolution() when existing != null:
return existing(_that.categoryId);case CreateCategoryResolution() when create != null:
return create(_that.name,_that.type);case IncomeByNoteCategoryResolution() when incomeByNote != null:
return incomeByNote(_that.salaryCategoryId,_that.otherCategoryId);case _:
  return null;

}
}

}

/// @nodoc


class ExistingCategoryResolution implements CategoryResolution {
  const ExistingCategoryResolution(this.categoryId);
  

 final  int categoryId;

/// Create a copy of CategoryResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExistingCategoryResolutionCopyWith<ExistingCategoryResolution> get copyWith => _$ExistingCategoryResolutionCopyWithImpl<ExistingCategoryResolution>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ExistingCategoryResolution&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,categoryId);
}

@override
String toString() {
    return 'CategoryResolution.existing(categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class $ExistingCategoryResolutionCopyWith<$Res> implements $CategoryResolutionCopyWith<$Res> {
  factory $ExistingCategoryResolutionCopyWith(ExistingCategoryResolution value, $Res Function(ExistingCategoryResolution) _then) = _$ExistingCategoryResolutionCopyWithImpl;
@useResult
$Res call({
 int categoryId
});




}
/// @nodoc
class _$ExistingCategoryResolutionCopyWithImpl<$Res>
    implements $ExistingCategoryResolutionCopyWith<$Res> {
  _$ExistingCategoryResolutionCopyWithImpl(this._self, this._then);

  final ExistingCategoryResolution _self;
  final $Res Function(ExistingCategoryResolution) _then;

/// Create a copy of CategoryResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = null,}) {
  return _then(ExistingCategoryResolution(
null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class CreateCategoryResolution implements CategoryResolution {
  const CreateCategoryResolution({required this.name, required this.type});
  

 final  String name;
 final  CategoryType type;

/// Create a copy of CategoryResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateCategoryResolutionCopyWith<CreateCategoryResolution> get copyWith => _$CreateCategoryResolutionCopyWithImpl<CreateCategoryResolution>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateCategoryResolution&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,type);
}

@override
String toString() {
    return 'CategoryResolution.create(name: $name, type: $type)';
}


}

/// @nodoc
abstract mixin class $CreateCategoryResolutionCopyWith<$Res> implements $CategoryResolutionCopyWith<$Res> {
  factory $CreateCategoryResolutionCopyWith(CreateCategoryResolution value, $Res Function(CreateCategoryResolution) _then) = _$CreateCategoryResolutionCopyWithImpl;
@useResult
$Res call({
 String name, CategoryType type
});




}
/// @nodoc
class _$CreateCategoryResolutionCopyWithImpl<$Res>
    implements $CreateCategoryResolutionCopyWith<$Res> {
  _$CreateCategoryResolutionCopyWithImpl(this._self, this._then);

  final CreateCategoryResolution _self;
  final $Res Function(CreateCategoryResolution) _then;

/// Create a copy of CategoryResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,}) {
  return _then(CreateCategoryResolution(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,
  ));
}


}

/// @nodoc


class IncomeByNoteCategoryResolution implements CategoryResolution {
  const IncomeByNoteCategoryResolution({required this.salaryCategoryId, required this.otherCategoryId});
  

 final  int salaryCategoryId;
 final  int otherCategoryId;

/// Create a copy of CategoryResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomeByNoteCategoryResolutionCopyWith<IncomeByNoteCategoryResolution> get copyWith => _$IncomeByNoteCategoryResolutionCopyWithImpl<IncomeByNoteCategoryResolution>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomeByNoteCategoryResolution&&(identical(other.salaryCategoryId, salaryCategoryId) || other.salaryCategoryId == salaryCategoryId)&&(identical(other.otherCategoryId, otherCategoryId) || other.otherCategoryId == otherCategoryId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,salaryCategoryId,otherCategoryId);
}

@override
String toString() {
    return 'CategoryResolution.incomeByNote(salaryCategoryId: $salaryCategoryId, otherCategoryId: $otherCategoryId)';
}


}

/// @nodoc
abstract mixin class $IncomeByNoteCategoryResolutionCopyWith<$Res> implements $CategoryResolutionCopyWith<$Res> {
  factory $IncomeByNoteCategoryResolutionCopyWith(IncomeByNoteCategoryResolution value, $Res Function(IncomeByNoteCategoryResolution) _then) = _$IncomeByNoteCategoryResolutionCopyWithImpl;
@useResult
$Res call({
 int salaryCategoryId, int otherCategoryId
});




}
/// @nodoc
class _$IncomeByNoteCategoryResolutionCopyWithImpl<$Res>
    implements $IncomeByNoteCategoryResolutionCopyWith<$Res> {
  _$IncomeByNoteCategoryResolutionCopyWithImpl(this._self, this._then);

  final IncomeByNoteCategoryResolution _self;
  final $Res Function(IncomeByNoteCategoryResolution) _then;

/// Create a copy of CategoryResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? salaryCategoryId = null,Object? otherCategoryId = null,}) {
  return _then(IncomeByNoteCategoryResolution(
salaryCategoryId: null == salaryCategoryId ? _self.salaryCategoryId : salaryCategoryId // ignore: cast_nullable_to_non_nullable
as int,otherCategoryId: null == otherCategoryId ? _self.otherCategoryId : otherCategoryId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$CsvImportPlan {

/// [CsvLoadResult.validRows], duplicates included: the commit recounts
/// them against the database.
 List<CsvImportRow> get rows; Map<String, AccountResolution> get accounts; Map<String, CategoryResolution> get categories;/// The Salary category's label in every locale. Compared with each
/// income row's note after trimming and lower-casing both.
 Set<String> get salaryNotes;
/// Create a copy of CsvImportPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvImportPlanCopyWith<CsvImportPlan> get copyWith => _$CsvImportPlanCopyWithImpl<CsvImportPlan>(this as CsvImportPlan, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvImportPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportPlan&&const DeepCollectionEquality().equals(other.rows, _this.rows)&&const DeepCollectionEquality().equals(other.accounts, _this.accounts)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&const DeepCollectionEquality().equals(other.salaryNotes, _this.salaryNotes));
}


@override
int get hashCode {
  final _this = this as CsvImportPlan;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.rows),const DeepCollectionEquality().hash(_this.accounts),const DeepCollectionEquality().hash(_this.categories),const DeepCollectionEquality().hash(_this.salaryNotes));
}

@override
String toString() {
  final _this = this as CsvImportPlan;
  return 'CsvImportPlan(rows: ${_this.rows}, accounts: ${_this.accounts}, categories: ${_this.categories}, salaryNotes: ${_this.salaryNotes})';
}


}

/// @nodoc
abstract mixin class $CsvImportPlanCopyWith<$Res>  {
  factory $CsvImportPlanCopyWith(CsvImportPlan value, $Res Function(CsvImportPlan) _then) = _$CsvImportPlanCopyWithImpl;
@useResult
$Res call({
 List<CsvImportRow> rows, Map<String, AccountResolution> accounts, Map<String, CategoryResolution> categories, Set<String> salaryNotes
});




}
/// @nodoc
class _$CsvImportPlanCopyWithImpl<$Res>
    implements $CsvImportPlanCopyWith<$Res> {
  _$CsvImportPlanCopyWithImpl(this._self, this._then);

  final CsvImportPlan _self;
  final $Res Function(CsvImportPlan) _then;

/// Create a copy of CsvImportPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? accounts = null,Object? categories = null,Object? salaryNotes = null,}) {
  return _then(CsvImportPlan(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<CsvImportRow>,accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as Map<String, AccountResolution>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, CategoryResolution>,salaryNotes: null == salaryNotes ? _self.salaryNotes : salaryNotes // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CsvImportPlan].
extension CsvImportPlanPatterns on CsvImportPlan {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvImportPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvImportPlan() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvImportPlan value)  $default,){
final _that = this;
switch (_that) {
case _CsvImportPlan():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvImportPlan value)?  $default,){
final _that = this;
switch (_that) {
case _CsvImportPlan() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CsvImportRow> rows,  Map<String, AccountResolution> accounts,  Map<String, CategoryResolution> categories,  Set<String> salaryNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvImportPlan() when $default != null:
return $default(_that.rows,_that.accounts,_that.categories,_that.salaryNotes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CsvImportRow> rows,  Map<String, AccountResolution> accounts,  Map<String, CategoryResolution> categories,  Set<String> salaryNotes)  $default,) {final _that = this;
switch (_that) {
case _CsvImportPlan():
return $default(_that.rows,_that.accounts,_that.categories,_that.salaryNotes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CsvImportRow> rows,  Map<String, AccountResolution> accounts,  Map<String, CategoryResolution> categories,  Set<String> salaryNotes)?  $default,) {final _that = this;
switch (_that) {
case _CsvImportPlan() when $default != null:
return $default(_that.rows,_that.accounts,_that.categories,_that.salaryNotes);case _:
  return null;

}
}

}

/// @nodoc


class _CsvImportPlan implements CsvImportPlan {
  const _CsvImportPlan({required  List<CsvImportRow> rows, required  Map<String, AccountResolution> accounts, required  Map<String, CategoryResolution> categories, required  Set<String> salaryNotes}): _rows = rows,_accounts = accounts,_categories = categories,_salaryNotes = salaryNotes;
  

/// [CsvLoadResult.validRows], duplicates included: the commit recounts
/// them against the database.
 final  List<CsvImportRow> _rows;
/// [CsvLoadResult.validRows], duplicates included: the commit recounts
/// them against the database.
@override List<CsvImportRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  Map<String, AccountResolution> _accounts;
@override Map<String, AccountResolution> get accounts {
  if (_accounts is EqualUnmodifiableMapView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_accounts);
}

 final  Map<String, CategoryResolution> _categories;
@override Map<String, CategoryResolution> get categories {
  if (_categories is EqualUnmodifiableMapView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categories);
}

/// The Salary category's label in every locale. Compared with each
/// income row's note after trimming and lower-casing both.
 final  Set<String> _salaryNotes;
/// The Salary category's label in every locale. Compared with each
/// income row's note after trimming and lower-casing both.
@override Set<String> get salaryNotes {
  if (_salaryNotes is EqualUnmodifiableSetView) return _salaryNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_salaryNotes);
}


/// Create a copy of CsvImportPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvImportPlanCopyWith<_CsvImportPlan> get copyWith => __$CsvImportPlanCopyWithImpl<_CsvImportPlan>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvImportPlan&&const DeepCollectionEquality().equals(other.rows, _rows)&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&const DeepCollectionEquality().equals(other.categories, _categories)&&const DeepCollectionEquality().equals(other.salaryNotes, _salaryNotes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_accounts),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_salaryNotes));
}

@override
String toString() {
    return 'CsvImportPlan(rows: $rows, accounts: $accounts, categories: $categories, salaryNotes: $salaryNotes)';
}


}

/// @nodoc
abstract mixin class _$CsvImportPlanCopyWith<$Res> implements $CsvImportPlanCopyWith<$Res> {
  factory _$CsvImportPlanCopyWith(_CsvImportPlan value, $Res Function(_CsvImportPlan) _then) = __$CsvImportPlanCopyWithImpl;
@override @useResult
$Res call({
 List<CsvImportRow> rows, Map<String, AccountResolution> accounts, Map<String, CategoryResolution> categories, Set<String> salaryNotes
});




}
/// @nodoc
class __$CsvImportPlanCopyWithImpl<$Res>
    implements _$CsvImportPlanCopyWith<$Res> {
  __$CsvImportPlanCopyWithImpl(this._self, this._then);

  final _CsvImportPlan _self;
  final $Res Function(_CsvImportPlan) _then;

/// Create a copy of CsvImportPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? accounts = null,Object? categories = null,Object? salaryNotes = null,}) {
  return _then(_CsvImportPlan(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<CsvImportRow>,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as Map<String, AccountResolution>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, CategoryResolution>,salaryNotes: null == salaryNotes ? _self._salaryNotes : salaryNotes // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc
mixin _$CsvImportResult {

 int get importedCount; int get duplicateCount; int get createdAccountCount; int get createdCategoryCount;/// Currency codes of the inserted rows, for the exchange-rate refresh.
 Set<String> get currencyCodes;
/// Create a copy of CsvImportResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvImportResultCopyWith<CsvImportResult> get copyWith => _$CsvImportResultCopyWithImpl<CsvImportResult>(this as CsvImportResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvImportResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvImportResult&&(identical(other.importedCount, _this.importedCount) || other.importedCount == _this.importedCount)&&(identical(other.duplicateCount, _this.duplicateCount) || other.duplicateCount == _this.duplicateCount)&&(identical(other.createdAccountCount, _this.createdAccountCount) || other.createdAccountCount == _this.createdAccountCount)&&(identical(other.createdCategoryCount, _this.createdCategoryCount) || other.createdCategoryCount == _this.createdCategoryCount)&&const DeepCollectionEquality().equals(other.currencyCodes, _this.currencyCodes));
}


@override
int get hashCode {
  final _this = this as CsvImportResult;
  return Object.hash(runtimeType,_this.importedCount,_this.duplicateCount,_this.createdAccountCount,_this.createdCategoryCount,const DeepCollectionEquality().hash(_this.currencyCodes));
}

@override
String toString() {
  final _this = this as CsvImportResult;
  return 'CsvImportResult(importedCount: ${_this.importedCount}, duplicateCount: ${_this.duplicateCount}, createdAccountCount: ${_this.createdAccountCount}, createdCategoryCount: ${_this.createdCategoryCount}, currencyCodes: ${_this.currencyCodes})';
}


}

/// @nodoc
abstract mixin class $CsvImportResultCopyWith<$Res>  {
  factory $CsvImportResultCopyWith(CsvImportResult value, $Res Function(CsvImportResult) _then) = _$CsvImportResultCopyWithImpl;
@useResult
$Res call({
 int importedCount, int duplicateCount, int createdAccountCount, int createdCategoryCount, Set<String> currencyCodes
});




}
/// @nodoc
class _$CsvImportResultCopyWithImpl<$Res>
    implements $CsvImportResultCopyWith<$Res> {
  _$CsvImportResultCopyWithImpl(this._self, this._then);

  final CsvImportResult _self;
  final $Res Function(CsvImportResult) _then;

/// Create a copy of CsvImportResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? importedCount = null,Object? duplicateCount = null,Object? createdAccountCount = null,Object? createdCategoryCount = null,Object? currencyCodes = null,}) {
  return _then(CsvImportResult(
importedCount: null == importedCount ? _self.importedCount : importedCount // ignore: cast_nullable_to_non_nullable
as int,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,createdAccountCount: null == createdAccountCount ? _self.createdAccountCount : createdAccountCount // ignore: cast_nullable_to_non_nullable
as int,createdCategoryCount: null == createdCategoryCount ? _self.createdCategoryCount : createdCategoryCount // ignore: cast_nullable_to_non_nullable
as int,currencyCodes: null == currencyCodes ? _self.currencyCodes : currencyCodes // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CsvImportResult].
extension CsvImportResultPatterns on CsvImportResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CsvImportResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CsvImportResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CsvImportResult value)  $default,){
final _that = this;
switch (_that) {
case _CsvImportResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CsvImportResult value)?  $default,){
final _that = this;
switch (_that) {
case _CsvImportResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int importedCount,  int duplicateCount,  int createdAccountCount,  int createdCategoryCount,  Set<String> currencyCodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvImportResult() when $default != null:
return $default(_that.importedCount,_that.duplicateCount,_that.createdAccountCount,_that.createdCategoryCount,_that.currencyCodes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int importedCount,  int duplicateCount,  int createdAccountCount,  int createdCategoryCount,  Set<String> currencyCodes)  $default,) {final _that = this;
switch (_that) {
case _CsvImportResult():
return $default(_that.importedCount,_that.duplicateCount,_that.createdAccountCount,_that.createdCategoryCount,_that.currencyCodes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int importedCount,  int duplicateCount,  int createdAccountCount,  int createdCategoryCount,  Set<String> currencyCodes)?  $default,) {final _that = this;
switch (_that) {
case _CsvImportResult() when $default != null:
return $default(_that.importedCount,_that.duplicateCount,_that.createdAccountCount,_that.createdCategoryCount,_that.currencyCodes);case _:
  return null;

}
}

}

/// @nodoc


class _CsvImportResult implements CsvImportResult {
  const _CsvImportResult({required this.importedCount, required this.duplicateCount, required this.createdAccountCount, required this.createdCategoryCount, required  Set<String> currencyCodes}): _currencyCodes = currencyCodes;
  

@override final  int importedCount;
@override final  int duplicateCount;
@override final  int createdAccountCount;
@override final  int createdCategoryCount;
/// Currency codes of the inserted rows, for the exchange-rate refresh.
 final  Set<String> _currencyCodes;
/// Currency codes of the inserted rows, for the exchange-rate refresh.
@override Set<String> get currencyCodes {
  if (_currencyCodes is EqualUnmodifiableSetView) return _currencyCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_currencyCodes);
}


/// Create a copy of CsvImportResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvImportResultCopyWith<_CsvImportResult> get copyWith => __$CsvImportResultCopyWithImpl<_CsvImportResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvImportResult&&(identical(other.importedCount, importedCount) || other.importedCount == importedCount)&&(identical(other.duplicateCount, duplicateCount) || other.duplicateCount == duplicateCount)&&(identical(other.createdAccountCount, createdAccountCount) || other.createdAccountCount == createdAccountCount)&&(identical(other.createdCategoryCount, createdCategoryCount) || other.createdCategoryCount == createdCategoryCount)&&const DeepCollectionEquality().equals(other.currencyCodes, _currencyCodes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,importedCount,duplicateCount,createdAccountCount,createdCategoryCount,const DeepCollectionEquality().hash(_currencyCodes));
}

@override
String toString() {
    return 'CsvImportResult(importedCount: $importedCount, duplicateCount: $duplicateCount, createdAccountCount: $createdAccountCount, createdCategoryCount: $createdCategoryCount, currencyCodes: $currencyCodes)';
}


}

/// @nodoc
abstract mixin class _$CsvImportResultCopyWith<$Res> implements $CsvImportResultCopyWith<$Res> {
  factory _$CsvImportResultCopyWith(_CsvImportResult value, $Res Function(_CsvImportResult) _then) = __$CsvImportResultCopyWithImpl;
@override @useResult
$Res call({
 int importedCount, int duplicateCount, int createdAccountCount, int createdCategoryCount, Set<String> currencyCodes
});




}
/// @nodoc
class __$CsvImportResultCopyWithImpl<$Res>
    implements _$CsvImportResultCopyWith<$Res> {
  __$CsvImportResultCopyWithImpl(this._self, this._then);

  final _CsvImportResult _self;
  final $Res Function(_CsvImportResult) _then;

/// Create a copy of CsvImportResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? importedCount = null,Object? duplicateCount = null,Object? createdAccountCount = null,Object? createdCategoryCount = null,Object? currencyCodes = null,}) {
  return _then(_CsvImportResult(
importedCount: null == importedCount ? _self.importedCount : importedCount // ignore: cast_nullable_to_non_nullable
as int,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,createdAccountCount: null == createdAccountCount ? _self.createdAccountCount : createdAccountCount // ignore: cast_nullable_to_non_nullable
as int,createdCategoryCount: null == createdCategoryCount ? _self.createdCategoryCount : createdCategoryCount // ignore: cast_nullable_to_non_nullable
as int,currencyCodes: null == currencyCodes ? _self._currencyCodes : currencyCodes // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
