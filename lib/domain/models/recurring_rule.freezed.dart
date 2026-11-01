// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurringRule {

 int get id; String get name; int get amountMinorUnits; Currency get currency; int get categoryId; int get accountId; String? get memo; String get frequency; int? get dayOfWeek; int? get dayOfMonth; int? get monthOfYear; bool get isActive; bool get isArchived; DateTime get nextDueDate; String? get lastError; DateTime? get lastErrorAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringRuleCopyWith<RecurringRule> get copyWith => _$RecurringRuleCopyWithImpl<RecurringRule>(this as RecurringRule, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecurringRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRule&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amountMinorUnits, _this.amountMinorUnits) || other.amountMinorUnits == _this.amountMinorUnits)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.dayOfWeek, _this.dayOfWeek) || other.dayOfWeek == _this.dayOfWeek)&&(identical(other.dayOfMonth, _this.dayOfMonth) || other.dayOfMonth == _this.dayOfMonth)&&(identical(other.monthOfYear, _this.monthOfYear) || other.monthOfYear == _this.monthOfYear)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.isArchived, _this.isArchived) || other.isArchived == _this.isArchived)&&(identical(other.nextDueDate, _this.nextDueDate) || other.nextDueDate == _this.nextDueDate)&&(identical(other.lastError, _this.lastError) || other.lastError == _this.lastError)&&(identical(other.lastErrorAt, _this.lastErrorAt) || other.lastErrorAt == _this.lastErrorAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as RecurringRule;
  return Object.hash(runtimeType,_this.id,_this.name,_this.amountMinorUnits,_this.currency,_this.categoryId,_this.accountId,_this.memo,_this.frequency,_this.dayOfWeek,_this.dayOfMonth,_this.monthOfYear,_this.isActive,_this.isArchived,_this.nextDueDate,_this.lastError,_this.lastErrorAt,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as RecurringRule;
  return 'RecurringRule(id: ${_this.id}, name: ${_this.name}, amountMinorUnits: ${_this.amountMinorUnits}, currency: ${_this.currency}, categoryId: ${_this.categoryId}, accountId: ${_this.accountId}, memo: ${_this.memo}, frequency: ${_this.frequency}, dayOfWeek: ${_this.dayOfWeek}, dayOfMonth: ${_this.dayOfMonth}, monthOfYear: ${_this.monthOfYear}, isActive: ${_this.isActive}, isArchived: ${_this.isArchived}, nextDueDate: ${_this.nextDueDate}, lastError: ${_this.lastError}, lastErrorAt: ${_this.lastErrorAt}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $RecurringRuleCopyWith<$Res>  {
  factory $RecurringRuleCopyWith(RecurringRule value, $Res Function(RecurringRule) _then) = _$RecurringRuleCopyWithImpl;
@useResult
$Res call({
 int id, String name, int amountMinorUnits, Currency currency, int categoryId, int accountId, String? memo, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear, bool isActive, bool isArchived, DateTime nextDueDate, String? lastError, DateTime? lastErrorAt, DateTime createdAt, DateTime updatedAt
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$RecurringRuleCopyWithImpl<$Res>
    implements $RecurringRuleCopyWith<$Res> {
  _$RecurringRuleCopyWithImpl(this._self, this._then);

  final RecurringRule _self;
  final $Res Function(RecurringRule) _then;

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = null,Object? accountId = null,Object? memo = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,Object? isActive = null,Object? isArchived = null,Object? nextDueDate = null,Object? lastError = freezed,Object? lastErrorAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(RecurringRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastErrorAt: freezed == lastErrorAt ? _self.lastErrorAt : lastErrorAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecurringRule].
extension RecurringRulePatterns on RecurringRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringRule value)  $default,){
final _that = this;
switch (_that) {
case _RecurringRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringRule value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isActive,  bool isArchived,  DateTime nextDueDate,  String? lastError,  DateTime? lastErrorAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
return $default(_that.id,_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isActive,_that.isArchived,_that.nextDueDate,_that.lastError,_that.lastErrorAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isActive,  bool isArchived,  DateTime nextDueDate,  String? lastError,  DateTime? lastErrorAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RecurringRule():
return $default(_that.id,_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isActive,_that.isArchived,_that.nextDueDate,_that.lastError,_that.lastErrorAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isActive,  bool isArchived,  DateTime nextDueDate,  String? lastError,  DateTime? lastErrorAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
return $default(_that.id,_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isActive,_that.isArchived,_that.nextDueDate,_that.lastError,_that.lastErrorAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RecurringRule implements RecurringRule {
  const _RecurringRule({required this.id, required this.name, required this.amountMinorUnits, required this.currency, required this.categoryId, required this.accountId, this.memo, required this.frequency, this.dayOfWeek, this.dayOfMonth, this.monthOfYear, required this.isActive, required this.isArchived, required this.nextDueDate, this.lastError, this.lastErrorAt, required this.createdAt, required this.updatedAt});
  

@override final  int id;
@override final  String name;
@override final  int amountMinorUnits;
@override final  Currency currency;
@override final  int categoryId;
@override final  int accountId;
@override final  String? memo;
@override final  String frequency;
@override final  int? dayOfWeek;
@override final  int? dayOfMonth;
@override final  int? monthOfYear;
@override final  bool isActive;
@override final  bool isArchived;
@override final  DateTime nextDueDate;
@override final  String? lastError;
@override final  DateTime? lastErrorAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringRuleCopyWith<_RecurringRule> get copyWith => __$RecurringRuleCopyWithImpl<_RecurringRule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringRule&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.monthOfYear, monthOfYear) || other.monthOfYear == monthOfYear)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastErrorAt, lastErrorAt) || other.lastErrorAt == lastErrorAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,amountMinorUnits,currency,categoryId,accountId,memo,frequency,dayOfWeek,dayOfMonth,monthOfYear,isActive,isArchived,nextDueDate,lastError,lastErrorAt,createdAt,updatedAt);
}

@override
String toString() {
    return 'RecurringRule(id: $id, name: $name, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, memo: $memo, frequency: $frequency, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, monthOfYear: $monthOfYear, isActive: $isActive, isArchived: $isArchived, nextDueDate: $nextDueDate, lastError: $lastError, lastErrorAt: $lastErrorAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RecurringRuleCopyWith<$Res> implements $RecurringRuleCopyWith<$Res> {
  factory _$RecurringRuleCopyWith(_RecurringRule value, $Res Function(_RecurringRule) _then) = __$RecurringRuleCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int amountMinorUnits, Currency currency, int categoryId, int accountId, String? memo, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear, bool isActive, bool isArchived, DateTime nextDueDate, String? lastError, DateTime? lastErrorAt, DateTime createdAt, DateTime updatedAt
});


@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$RecurringRuleCopyWithImpl<$Res>
    implements _$RecurringRuleCopyWith<$Res> {
  __$RecurringRuleCopyWithImpl(this._self, this._then);

  final _RecurringRule _self;
  final $Res Function(_RecurringRule) _then;

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = null,Object? accountId = null,Object? memo = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,Object? isActive = null,Object? isArchived = null,Object? nextDueDate = null,Object? lastError = freezed,Object? lastErrorAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_RecurringRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastErrorAt: freezed == lastErrorAt ? _self.lastErrorAt : lastErrorAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}

// dart format on
