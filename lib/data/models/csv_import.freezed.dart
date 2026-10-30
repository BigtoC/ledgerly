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
 int get lineNumber; CsvRowErrorReason get reason;
/// Create a copy of CsvRowError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvRowErrorCopyWith<CsvRowError> get copyWith => _$CsvRowErrorCopyWithImpl<CsvRowError>(this as CsvRowError, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CsvRowError;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvRowError&&(identical(other.lineNumber, _this.lineNumber) || other.lineNumber == _this.lineNumber)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}


@override
int get hashCode {
  final _this = this as CsvRowError;
  return Object.hash(runtimeType,_this.lineNumber,_this.reason);
}

@override
String toString() {
  final _this = this as CsvRowError;
  return 'CsvRowError(lineNumber: ${_this.lineNumber}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $CsvRowErrorCopyWith<$Res>  {
  factory $CsvRowErrorCopyWith(CsvRowError value, $Res Function(CsvRowError) _then) = _$CsvRowErrorCopyWithImpl;
@useResult
$Res call({
 int lineNumber, CsvRowErrorReason reason
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
@pragma('vm:prefer-inline') @override $Res call({Object? lineNumber = null,Object? reason = null,}) {
  return _then(CsvRowError(
lineNumber: null == lineNumber ? _self.lineNumber : lineNumber // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CsvRowErrorReason,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int lineNumber,  CsvRowErrorReason reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CsvRowError() when $default != null:
return $default(_that.lineNumber,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int lineNumber,  CsvRowErrorReason reason)  $default,) {final _that = this;
switch (_that) {
case _CsvRowError():
return $default(_that.lineNumber,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int lineNumber,  CsvRowErrorReason reason)?  $default,) {final _that = this;
switch (_that) {
case _CsvRowError() when $default != null:
return $default(_that.lineNumber,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _CsvRowError implements CsvRowError {
  const _CsvRowError({required this.lineNumber, required this.reason});
  

/// 1-based physical line in the file; the header is line 1.
@override final  int lineNumber;
@override final  CsvRowErrorReason reason;

/// Create a copy of CsvRowError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CsvRowErrorCopyWith<_CsvRowError> get copyWith => __$CsvRowErrorCopyWithImpl<_CsvRowError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CsvRowError&&(identical(other.lineNumber, lineNumber) || other.lineNumber == lineNumber)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,lineNumber,reason);
}

@override
String toString() {
    return 'CsvRowError(lineNumber: $lineNumber, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$CsvRowErrorCopyWith<$Res> implements $CsvRowErrorCopyWith<$Res> {
  factory _$CsvRowErrorCopyWith(_CsvRowError value, $Res Function(_CsvRowError) _then) = __$CsvRowErrorCopyWithImpl;
@override @useResult
$Res call({
 int lineNumber, CsvRowErrorReason reason
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
@override @pragma('vm:prefer-inline') $Res call({Object? lineNumber = null,Object? reason = null,}) {
  return _then(_CsvRowError(
lineNumber: null == lineNumber ? _self.lineNumber : lineNumber // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as CsvRowErrorReason,
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

// dart format on
