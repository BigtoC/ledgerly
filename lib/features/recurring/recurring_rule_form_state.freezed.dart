// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rule_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurringRuleFormState {

 String get name; int get amountMinorUnits; Currency get currency; int? get categoryId; int? get accountId; String? get memo; String get frequency; int? get dayOfWeek; int? get dayOfMonth; int? get monthOfYear; bool get isEdit; bool get isLoading; int? get pendingItemCount; RecurringFormErrorKey? get nameError; RecurringFormErrorKey? get categoryError; RecurringFormErrorKey? get accountError; RecurringFormErrorKey? get frequencyFieldError; RecurringFormError? get formError; bool get postSaveGenerationFailed;
/// Create a copy of RecurringRuleFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringRuleFormStateCopyWith<RecurringRuleFormState> get copyWith => _$RecurringRuleFormStateCopyWithImpl<RecurringRuleFormState>(this as RecurringRuleFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRuleFormState&&(identical(other.name, name) || other.name == name)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.monthOfYear, monthOfYear) || other.monthOfYear == monthOfYear)&&(identical(other.isEdit, isEdit) || other.isEdit == isEdit)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.pendingItemCount, pendingItemCount) || other.pendingItemCount == pendingItemCount)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.categoryError, categoryError) || other.categoryError == categoryError)&&(identical(other.accountError, accountError) || other.accountError == accountError)&&(identical(other.frequencyFieldError, frequencyFieldError) || other.frequencyFieldError == frequencyFieldError)&&(identical(other.formError, formError) || other.formError == formError)&&(identical(other.postSaveGenerationFailed, postSaveGenerationFailed) || other.postSaveGenerationFailed == postSaveGenerationFailed));
}


@override
int get hashCode => Object.hashAll([runtimeType,name,amountMinorUnits,currency,categoryId,accountId,memo,frequency,dayOfWeek,dayOfMonth,monthOfYear,isEdit,isLoading,pendingItemCount,nameError,categoryError,accountError,frequencyFieldError,formError,postSaveGenerationFailed]);

@override
String toString() {
  return 'RecurringRuleFormState(name: $name, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, memo: $memo, frequency: $frequency, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, monthOfYear: $monthOfYear, isEdit: $isEdit, isLoading: $isLoading, pendingItemCount: $pendingItemCount, nameError: $nameError, categoryError: $categoryError, accountError: $accountError, frequencyFieldError: $frequencyFieldError, formError: $formError, postSaveGenerationFailed: $postSaveGenerationFailed)';
}


}

/// @nodoc
abstract mixin class $RecurringRuleFormStateCopyWith<$Res>  {
  factory $RecurringRuleFormStateCopyWith(RecurringRuleFormState value, $Res Function(RecurringRuleFormState) _then) = _$RecurringRuleFormStateCopyWithImpl;
@useResult
$Res call({
 String name, int amountMinorUnits, Currency currency, int? categoryId, int? accountId, String? memo, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear, bool isEdit, bool isLoading, int? pendingItemCount, RecurringFormErrorKey? nameError, RecurringFormErrorKey? categoryError, RecurringFormErrorKey? accountError, RecurringFormErrorKey? frequencyFieldError, RecurringFormError? formError, bool postSaveGenerationFailed
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$RecurringRuleFormStateCopyWithImpl<$Res>
    implements $RecurringRuleFormStateCopyWith<$Res> {
  _$RecurringRuleFormStateCopyWithImpl(this._self, this._then);

  final RecurringRuleFormState _self;
  final $Res Function(RecurringRuleFormState) _then;

/// Create a copy of RecurringRuleFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = freezed,Object? accountId = freezed,Object? memo = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,Object? isEdit = null,Object? isLoading = null,Object? pendingItemCount = freezed,Object? nameError = freezed,Object? categoryError = freezed,Object? accountError = freezed,Object? frequencyFieldError = freezed,Object? formError = freezed,Object? postSaveGenerationFailed = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,isEdit: null == isEdit ? _self.isEdit : isEdit // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,pendingItemCount: freezed == pendingItemCount ? _self.pendingItemCount : pendingItemCount // ignore: cast_nullable_to_non_nullable
as int?,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,categoryError: freezed == categoryError ? _self.categoryError : categoryError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,accountError: freezed == accountError ? _self.accountError : accountError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,frequencyFieldError: freezed == frequencyFieldError ? _self.frequencyFieldError : frequencyFieldError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,formError: freezed == formError ? _self.formError : formError // ignore: cast_nullable_to_non_nullable
as RecurringFormError?,postSaveGenerationFailed: null == postSaveGenerationFailed ? _self.postSaveGenerationFailed : postSaveGenerationFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of RecurringRuleFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecurringRuleFormState].
extension RecurringRuleFormStatePatterns on RecurringRuleFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringRuleFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringRuleFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringRuleFormState value)  $default,){
final _that = this;
switch (_that) {
case _RecurringRuleFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringRuleFormState value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringRuleFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int amountMinorUnits,  Currency currency,  int? categoryId,  int? accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isEdit,  bool isLoading,  int? pendingItemCount,  RecurringFormErrorKey? nameError,  RecurringFormErrorKey? categoryError,  RecurringFormErrorKey? accountError,  RecurringFormErrorKey? frequencyFieldError,  RecurringFormError? formError,  bool postSaveGenerationFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringRuleFormState() when $default != null:
return $default(_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isEdit,_that.isLoading,_that.pendingItemCount,_that.nameError,_that.categoryError,_that.accountError,_that.frequencyFieldError,_that.formError,_that.postSaveGenerationFailed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int amountMinorUnits,  Currency currency,  int? categoryId,  int? accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isEdit,  bool isLoading,  int? pendingItemCount,  RecurringFormErrorKey? nameError,  RecurringFormErrorKey? categoryError,  RecurringFormErrorKey? accountError,  RecurringFormErrorKey? frequencyFieldError,  RecurringFormError? formError,  bool postSaveGenerationFailed)  $default,) {final _that = this;
switch (_that) {
case _RecurringRuleFormState():
return $default(_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isEdit,_that.isLoading,_that.pendingItemCount,_that.nameError,_that.categoryError,_that.accountError,_that.frequencyFieldError,_that.formError,_that.postSaveGenerationFailed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int amountMinorUnits,  Currency currency,  int? categoryId,  int? accountId,  String? memo,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isEdit,  bool isLoading,  int? pendingItemCount,  RecurringFormErrorKey? nameError,  RecurringFormErrorKey? categoryError,  RecurringFormErrorKey? accountError,  RecurringFormErrorKey? frequencyFieldError,  RecurringFormError? formError,  bool postSaveGenerationFailed)?  $default,) {final _that = this;
switch (_that) {
case _RecurringRuleFormState() when $default != null:
return $default(_that.name,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isEdit,_that.isLoading,_that.pendingItemCount,_that.nameError,_that.categoryError,_that.accountError,_that.frequencyFieldError,_that.formError,_that.postSaveGenerationFailed);case _:
  return null;

}
}

}

/// @nodoc


class _RecurringRuleFormState extends RecurringRuleFormState {
  const _RecurringRuleFormState({this.name = '', this.amountMinorUnits = 0, required this.currency, this.categoryId, this.accountId, this.memo, this.frequency = 'monthly', this.dayOfWeek, this.dayOfMonth, this.monthOfYear, this.isEdit = false, this.isLoading = false, this.pendingItemCount, this.nameError, this.categoryError, this.accountError, this.frequencyFieldError, this.formError, this.postSaveGenerationFailed = false}): super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  int amountMinorUnits;
@override final  Currency currency;
@override final  int? categoryId;
@override final  int? accountId;
@override final  String? memo;
@override@JsonKey() final  String frequency;
@override final  int? dayOfWeek;
@override final  int? dayOfMonth;
@override final  int? monthOfYear;
@override@JsonKey() final  bool isEdit;
@override@JsonKey() final  bool isLoading;
@override final  int? pendingItemCount;
@override final  RecurringFormErrorKey? nameError;
@override final  RecurringFormErrorKey? categoryError;
@override final  RecurringFormErrorKey? accountError;
@override final  RecurringFormErrorKey? frequencyFieldError;
@override final  RecurringFormError? formError;
@override@JsonKey() final  bool postSaveGenerationFailed;

/// Create a copy of RecurringRuleFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringRuleFormStateCopyWith<_RecurringRuleFormState> get copyWith => __$RecurringRuleFormStateCopyWithImpl<_RecurringRuleFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringRuleFormState&&(identical(other.name, name) || other.name == name)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.monthOfYear, monthOfYear) || other.monthOfYear == monthOfYear)&&(identical(other.isEdit, isEdit) || other.isEdit == isEdit)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.pendingItemCount, pendingItemCount) || other.pendingItemCount == pendingItemCount)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.categoryError, categoryError) || other.categoryError == categoryError)&&(identical(other.accountError, accountError) || other.accountError == accountError)&&(identical(other.frequencyFieldError, frequencyFieldError) || other.frequencyFieldError == frequencyFieldError)&&(identical(other.formError, formError) || other.formError == formError)&&(identical(other.postSaveGenerationFailed, postSaveGenerationFailed) || other.postSaveGenerationFailed == postSaveGenerationFailed));
}


@override
int get hashCode => Object.hashAll([runtimeType,name,amountMinorUnits,currency,categoryId,accountId,memo,frequency,dayOfWeek,dayOfMonth,monthOfYear,isEdit,isLoading,pendingItemCount,nameError,categoryError,accountError,frequencyFieldError,formError,postSaveGenerationFailed]);

@override
String toString() {
  return 'RecurringRuleFormState(name: $name, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, memo: $memo, frequency: $frequency, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, monthOfYear: $monthOfYear, isEdit: $isEdit, isLoading: $isLoading, pendingItemCount: $pendingItemCount, nameError: $nameError, categoryError: $categoryError, accountError: $accountError, frequencyFieldError: $frequencyFieldError, formError: $formError, postSaveGenerationFailed: $postSaveGenerationFailed)';
}


}

/// @nodoc
abstract mixin class _$RecurringRuleFormStateCopyWith<$Res> implements $RecurringRuleFormStateCopyWith<$Res> {
  factory _$RecurringRuleFormStateCopyWith(_RecurringRuleFormState value, $Res Function(_RecurringRuleFormState) _then) = __$RecurringRuleFormStateCopyWithImpl;
@override @useResult
$Res call({
 String name, int amountMinorUnits, Currency currency, int? categoryId, int? accountId, String? memo, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear, bool isEdit, bool isLoading, int? pendingItemCount, RecurringFormErrorKey? nameError, RecurringFormErrorKey? categoryError, RecurringFormErrorKey? accountError, RecurringFormErrorKey? frequencyFieldError, RecurringFormError? formError, bool postSaveGenerationFailed
});


@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$RecurringRuleFormStateCopyWithImpl<$Res>
    implements _$RecurringRuleFormStateCopyWith<$Res> {
  __$RecurringRuleFormStateCopyWithImpl(this._self, this._then);

  final _RecurringRuleFormState _self;
  final $Res Function(_RecurringRuleFormState) _then;

/// Create a copy of RecurringRuleFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = freezed,Object? accountId = freezed,Object? memo = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,Object? isEdit = null,Object? isLoading = null,Object? pendingItemCount = freezed,Object? nameError = freezed,Object? categoryError = freezed,Object? accountError = freezed,Object? frequencyFieldError = freezed,Object? formError = freezed,Object? postSaveGenerationFailed = null,}) {
  return _then(_RecurringRuleFormState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,isEdit: null == isEdit ? _self.isEdit : isEdit // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,pendingItemCount: freezed == pendingItemCount ? _self.pendingItemCount : pendingItemCount // ignore: cast_nullable_to_non_nullable
as int?,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,categoryError: freezed == categoryError ? _self.categoryError : categoryError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,accountError: freezed == accountError ? _self.accountError : accountError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,frequencyFieldError: freezed == frequencyFieldError ? _self.frequencyFieldError : frequencyFieldError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,formError: freezed == formError ? _self.formError : formError // ignore: cast_nullable_to_non_nullable
as RecurringFormError?,postSaveGenerationFailed: null == postSaveGenerationFailed ? _self.postSaveGenerationFailed : postSaveGenerationFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of RecurringRuleFormState
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
