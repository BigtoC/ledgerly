// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rule_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurringRuleDraft {

 String get name; int get amountMinorUnits; Currency get currency; int get categoryId; int get accountId; String? get memo; String get frequency; int? get dayOfWeek; int? get dayOfMonth; int? get monthOfYear;
/// Create a copy of RecurringRuleDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringRuleDraftCopyWith<RecurringRuleDraft> get copyWith => _$RecurringRuleDraftCopyWithImpl<RecurringRuleDraft>(this as RecurringRuleDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRuleDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.monthOfYear, monthOfYear) || other.monthOfYear == monthOfYear));
}


@override
int get hashCode => Object.hash(runtimeType,name,amountMinorUnits,currency,categoryId,accountId,memo,frequency,dayOfWeek,dayOfMonth,monthOfYear);

@override
String toString() {
  return 'RecurringRuleDraft(name: $name, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, memo: $memo, frequency: $frequency, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, monthOfYear: $monthOfYear)';
}


}

/// @nodoc
abstract mixin class $RecurringRuleDraftCopyWith<$Res>  {
  factory $RecurringRuleDraftCopyWith(RecurringRuleDraft value, $Res Function(RecurringRuleDraft) _then) = _$RecurringRuleDraftCopyWithImpl;
@useResult
$Res call({
 String name, int amountMinorUnits, Currency currency, int categoryId, int accountId, String? memo, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$RecurringRuleDraftCopyWithImpl<$Res>
    implements $RecurringRuleDraftCopyWith<$Res> {
  _$RecurringRuleDraftCopyWithImpl(this._self, this._then);

  final RecurringRuleDraft _self;
  final $Res Function(RecurringRuleDraft) _then;

/// Create a copy of RecurringRuleDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = null,Object? accountId = null,Object? memo = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of RecurringRuleDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecurringRuleDraft].
extension RecurringRuleDraftPatterns on RecurringRuleDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringRuleDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringRuleDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringRuleDraft value)  $default,){
final _that = this;
switch (_that) {
case _RecurringRuleDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringRuleDraft value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringRuleDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringRuleDraft() when $default != null:
return $default(_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear)  $default,) {final _that = this;
switch (_that) {
case _RecurringRuleDraft():
return $default(_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear)?  $default,) {final _that = this;
switch (_that) {
case _RecurringRuleDraft() when $default != null:
return $default(_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear);case _:
  return null;

}
}

}

/// @nodoc


class _RecurringRuleDraft implements RecurringRuleDraft {
  const _RecurringRuleDraft({required this.name, required this.amountMinorUnits, required this.currency, required this.categoryId, required this.accountId, this.memo, required this.frequency, this.dayOfWeek, this.dayOfMonth, this.monthOfYear});
  

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

/// Create a copy of RecurringRuleDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringRuleDraftCopyWith<_RecurringRuleDraft> get copyWith => __$RecurringRuleDraftCopyWithImpl<_RecurringRuleDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringRuleDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.monthOfYear, monthOfYear) || other.monthOfYear == monthOfYear));
}


@override
int get hashCode => Object.hash(runtimeType,name,amountMinorUnits,currency,categoryId,accountId,memo,frequency,dayOfWeek,dayOfMonth,monthOfYear);

@override
String toString() {
  return 'RecurringRuleDraft(name: $name, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, memo: $memo, frequency: $frequency, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, monthOfYear: $monthOfYear)';
}


}

/// @nodoc
abstract mixin class _$RecurringRuleDraftCopyWith<$Res> implements $RecurringRuleDraftCopyWith<$Res> {
  factory _$RecurringRuleDraftCopyWith(_RecurringRuleDraft value, $Res Function(_RecurringRuleDraft) _then) = __$RecurringRuleDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, int amountMinorUnits, Currency currency, int categoryId, int accountId, String? memo, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear
});


@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$RecurringRuleDraftCopyWithImpl<$Res>
    implements _$RecurringRuleDraftCopyWith<$Res> {
  __$RecurringRuleDraftCopyWithImpl(this._self, this._then);

  final _RecurringRuleDraft _self;
  final $Res Function(_RecurringRuleDraft) _then;

/// Create a copy of RecurringRuleDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = null,Object? accountId = null,Object? memo = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,}) {
  return _then(_RecurringRuleDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of RecurringRuleDraft
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
