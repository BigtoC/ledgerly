// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rule_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurringRuleFormState {

/// User-visible label for the rule. Stored in `recurring_rules.memo`
/// and copied verbatim into `recurring_rules.name` on save (the form
/// no longer surfaces a separate Name field).
 String get memo; int get amountMinorUnits; Currency get currency; int? get categoryId; int? get accountId; String get frequency; int? get dayOfWeek; int? get dayOfMonth; int? get monthOfYear; bool get isEdit; bool get isLoading; int? get pendingItemCount;/// Full calculator snapshot used by `AmountDisplay`.
 KeypadState get keypad; RecurringFormErrorKey? get nameError; RecurringFormErrorKey? get categoryError; RecurringFormErrorKey? get accountError; RecurringFormErrorKey? get frequencyFieldError; RecurringFormError? get formError;
/// Create a copy of RecurringRuleFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringRuleFormStateCopyWith<RecurringRuleFormState> get copyWith => _$RecurringRuleFormStateCopyWithImpl<RecurringRuleFormState>(this as RecurringRuleFormState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecurringRuleFormState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRuleFormState&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.amountMinorUnits, _this.amountMinorUnits) || other.amountMinorUnits == _this.amountMinorUnits)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.dayOfWeek, _this.dayOfWeek) || other.dayOfWeek == _this.dayOfWeek)&&(identical(other.dayOfMonth, _this.dayOfMonth) || other.dayOfMonth == _this.dayOfMonth)&&(identical(other.monthOfYear, _this.monthOfYear) || other.monthOfYear == _this.monthOfYear)&&(identical(other.isEdit, _this.isEdit) || other.isEdit == _this.isEdit)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.pendingItemCount, _this.pendingItemCount) || other.pendingItemCount == _this.pendingItemCount)&&(identical(other.keypad, _this.keypad) || other.keypad == _this.keypad)&&(identical(other.nameError, _this.nameError) || other.nameError == _this.nameError)&&(identical(other.categoryError, _this.categoryError) || other.categoryError == _this.categoryError)&&(identical(other.accountError, _this.accountError) || other.accountError == _this.accountError)&&(identical(other.frequencyFieldError, _this.frequencyFieldError) || other.frequencyFieldError == _this.frequencyFieldError)&&(identical(other.formError, _this.formError) || other.formError == _this.formError));
}


@override
int get hashCode {
  final _this = this as RecurringRuleFormState;
  return Object.hash(runtimeType,_this.memo,_this.amountMinorUnits,_this.currency,_this.categoryId,_this.accountId,_this.frequency,_this.dayOfWeek,_this.dayOfMonth,_this.monthOfYear,_this.isEdit,_this.isLoading,_this.pendingItemCount,_this.keypad,_this.nameError,_this.categoryError,_this.accountError,_this.frequencyFieldError,_this.formError);
}

@override
String toString() {
  final _this = this as RecurringRuleFormState;
  return 'RecurringRuleFormState(memo: ${_this.memo}, amountMinorUnits: ${_this.amountMinorUnits}, currency: ${_this.currency}, categoryId: ${_this.categoryId}, accountId: ${_this.accountId}, frequency: ${_this.frequency}, dayOfWeek: ${_this.dayOfWeek}, dayOfMonth: ${_this.dayOfMonth}, monthOfYear: ${_this.monthOfYear}, isEdit: ${_this.isEdit}, isLoading: ${_this.isLoading}, pendingItemCount: ${_this.pendingItemCount}, keypad: ${_this.keypad}, nameError: ${_this.nameError}, categoryError: ${_this.categoryError}, accountError: ${_this.accountError}, frequencyFieldError: ${_this.frequencyFieldError}, formError: ${_this.formError})';
}


}

/// @nodoc
abstract mixin class $RecurringRuleFormStateCopyWith<$Res>  {
  factory $RecurringRuleFormStateCopyWith(RecurringRuleFormState value, $Res Function(RecurringRuleFormState) _then) = _$RecurringRuleFormStateCopyWithImpl;
@useResult
$Res call({
 String memo, int amountMinorUnits, Currency currency, int? categoryId, int? accountId, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear, bool isEdit, bool isLoading, int? pendingItemCount, KeypadState keypad, RecurringFormErrorKey? nameError, RecurringFormErrorKey? categoryError, RecurringFormErrorKey? accountError, RecurringFormErrorKey? frequencyFieldError, RecurringFormError? formError
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
@pragma('vm:prefer-inline') @override $Res call({Object? memo = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = freezed,Object? accountId = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,Object? isEdit = null,Object? isLoading = null,Object? pendingItemCount = freezed,Object? keypad = null,Object? nameError = freezed,Object? categoryError = freezed,Object? accountError = freezed,Object? frequencyFieldError = freezed,Object? formError = freezed,}) {
  return _then(RecurringRuleFormState(
memo: null == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,isEdit: null == isEdit ? _self.isEdit : isEdit // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,pendingItemCount: freezed == pendingItemCount ? _self.pendingItemCount : pendingItemCount // ignore: cast_nullable_to_non_nullable
as int?,keypad: null == keypad ? _self.keypad : keypad // ignore: cast_nullable_to_non_nullable
as KeypadState,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,categoryError: freezed == categoryError ? _self.categoryError : categoryError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,accountError: freezed == accountError ? _self.accountError : accountError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,frequencyFieldError: freezed == frequencyFieldError ? _self.frequencyFieldError : frequencyFieldError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,formError: freezed == formError ? _self.formError : formError // ignore: cast_nullable_to_non_nullable
as RecurringFormError?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String memo,  int amountMinorUnits,  Currency currency,  int? categoryId,  int? accountId,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isEdit,  bool isLoading,  int? pendingItemCount,  KeypadState keypad,  RecurringFormErrorKey? nameError,  RecurringFormErrorKey? categoryError,  RecurringFormErrorKey? accountError,  RecurringFormErrorKey? frequencyFieldError,  RecurringFormError? formError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringRuleFormState() when $default != null:
return $default(_that.memo,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isEdit,_that.isLoading,_that.pendingItemCount,_that.keypad,_that.nameError,_that.categoryError,_that.accountError,_that.frequencyFieldError,_that.formError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String memo,  int amountMinorUnits,  Currency currency,  int? categoryId,  int? accountId,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isEdit,  bool isLoading,  int? pendingItemCount,  KeypadState keypad,  RecurringFormErrorKey? nameError,  RecurringFormErrorKey? categoryError,  RecurringFormErrorKey? accountError,  RecurringFormErrorKey? frequencyFieldError,  RecurringFormError? formError)  $default,) {final _that = this;
switch (_that) {
case _RecurringRuleFormState():
return $default(_that.memo,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isEdit,_that.isLoading,_that.pendingItemCount,_that.keypad,_that.nameError,_that.categoryError,_that.accountError,_that.frequencyFieldError,_that.formError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String memo,  int amountMinorUnits,  Currency currency,  int? categoryId,  int? accountId,  String frequency,  int? dayOfWeek,  int? dayOfMonth,  int? monthOfYear,  bool isEdit,  bool isLoading,  int? pendingItemCount,  KeypadState keypad,  RecurringFormErrorKey? nameError,  RecurringFormErrorKey? categoryError,  RecurringFormErrorKey? accountError,  RecurringFormErrorKey? frequencyFieldError,  RecurringFormError? formError)?  $default,) {final _that = this;
switch (_that) {
case _RecurringRuleFormState() when $default != null:
return $default(_that.memo,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.frequency,_that.dayOfWeek,_that.dayOfMonth,_that.monthOfYear,_that.isEdit,_that.isLoading,_that.pendingItemCount,_that.keypad,_that.nameError,_that.categoryError,_that.accountError,_that.frequencyFieldError,_that.formError);case _:
  return null;

}
}

}

/// @nodoc


class _RecurringRuleFormState extends RecurringRuleFormState {
  const _RecurringRuleFormState({this.memo = '', this.amountMinorUnits = 0, required this.currency, this.categoryId, this.accountId, this.frequency = 'monthly', this.dayOfWeek, this.dayOfMonth, this.monthOfYear, this.isEdit = false, this.isLoading = false, this.pendingItemCount, this.keypad = const KeypadState.initial(), this.nameError, this.categoryError, this.accountError, this.frequencyFieldError, this.formError}): super._();
  

/// User-visible label for the rule. Stored in `recurring_rules.memo`
/// and copied verbatim into `recurring_rules.name` on save (the form
/// no longer surfaces a separate Name field).
@override@JsonKey() final  String memo;
@override@JsonKey() final  int amountMinorUnits;
@override final  Currency currency;
@override final  int? categoryId;
@override final  int? accountId;
@override@JsonKey() final  String frequency;
@override final  int? dayOfWeek;
@override final  int? dayOfMonth;
@override final  int? monthOfYear;
@override@JsonKey() final  bool isEdit;
@override@JsonKey() final  bool isLoading;
@override final  int? pendingItemCount;
/// Full calculator snapshot used by `AmountDisplay`.
@override@JsonKey() final  KeypadState keypad;
@override final  RecurringFormErrorKey? nameError;
@override final  RecurringFormErrorKey? categoryError;
@override final  RecurringFormErrorKey? accountError;
@override final  RecurringFormErrorKey? frequencyFieldError;
@override final  RecurringFormError? formError;

/// Create a copy of RecurringRuleFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringRuleFormStateCopyWith<_RecurringRuleFormState> get copyWith => __$RecurringRuleFormStateCopyWithImpl<_RecurringRuleFormState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringRuleFormState&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.monthOfYear, monthOfYear) || other.monthOfYear == monthOfYear)&&(identical(other.isEdit, isEdit) || other.isEdit == isEdit)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.pendingItemCount, pendingItemCount) || other.pendingItemCount == pendingItemCount)&&(identical(other.keypad, keypad) || other.keypad == keypad)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.categoryError, categoryError) || other.categoryError == categoryError)&&(identical(other.accountError, accountError) || other.accountError == accountError)&&(identical(other.frequencyFieldError, frequencyFieldError) || other.frequencyFieldError == frequencyFieldError)&&(identical(other.formError, formError) || other.formError == formError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,memo,amountMinorUnits,currency,categoryId,accountId,frequency,dayOfWeek,dayOfMonth,monthOfYear,isEdit,isLoading,pendingItemCount,keypad,nameError,categoryError,accountError,frequencyFieldError,formError);
}

@override
String toString() {
    return 'RecurringRuleFormState(memo: $memo, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, frequency: $frequency, dayOfWeek: $dayOfWeek, dayOfMonth: $dayOfMonth, monthOfYear: $monthOfYear, isEdit: $isEdit, isLoading: $isLoading, pendingItemCount: $pendingItemCount, keypad: $keypad, nameError: $nameError, categoryError: $categoryError, accountError: $accountError, frequencyFieldError: $frequencyFieldError, formError: $formError)';
}


}

/// @nodoc
abstract mixin class _$RecurringRuleFormStateCopyWith<$Res> implements $RecurringRuleFormStateCopyWith<$Res> {
  factory _$RecurringRuleFormStateCopyWith(_RecurringRuleFormState value, $Res Function(_RecurringRuleFormState) _then) = __$RecurringRuleFormStateCopyWithImpl;
@override @useResult
$Res call({
 String memo, int amountMinorUnits, Currency currency, int? categoryId, int? accountId, String frequency, int? dayOfWeek, int? dayOfMonth, int? monthOfYear, bool isEdit, bool isLoading, int? pendingItemCount, KeypadState keypad, RecurringFormErrorKey? nameError, RecurringFormErrorKey? categoryError, RecurringFormErrorKey? accountError, RecurringFormErrorKey? frequencyFieldError, RecurringFormError? formError
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
@override @pragma('vm:prefer-inline') $Res call({Object? memo = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = freezed,Object? accountId = freezed,Object? frequency = null,Object? dayOfWeek = freezed,Object? dayOfMonth = freezed,Object? monthOfYear = freezed,Object? isEdit = null,Object? isLoading = null,Object? pendingItemCount = freezed,Object? keypad = null,Object? nameError = freezed,Object? categoryError = freezed,Object? accountError = freezed,Object? frequencyFieldError = freezed,Object? formError = freezed,}) {
  return _then(_RecurringRuleFormState(
memo: null == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as int?,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,monthOfYear: freezed == monthOfYear ? _self.monthOfYear : monthOfYear // ignore: cast_nullable_to_non_nullable
as int?,isEdit: null == isEdit ? _self.isEdit : isEdit // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,pendingItemCount: freezed == pendingItemCount ? _self.pendingItemCount : pendingItemCount // ignore: cast_nullable_to_non_nullable
as int?,keypad: null == keypad ? _self.keypad : keypad // ignore: cast_nullable_to_non_nullable
as KeypadState,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,categoryError: freezed == categoryError ? _self.categoryError : categoryError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,accountError: freezed == accountError ? _self.accountError : accountError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,frequencyFieldError: freezed == frequencyFieldError ? _self.frequencyFieldError : frequencyFieldError // ignore: cast_nullable_to_non_nullable
as RecurringFormErrorKey?,formError: freezed == formError ? _self.formError : formError // ignore: cast_nullable_to_non_nullable
as RecurringFormError?,
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

/// @nodoc
mixin _$SaveRecurringRuleOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveRecurringRuleOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveRecurringRuleOutcome()';
}


}

/// @nodoc
class $SaveRecurringRuleOutcomeCopyWith<$Res>  {
$SaveRecurringRuleOutcomeCopyWith(SaveRecurringRuleOutcome _, $Res Function(SaveRecurringRuleOutcome) __);
}


/// Adds pattern-matching-related methods to [SaveRecurringRuleOutcome].
extension SaveRecurringRuleOutcomePatterns on SaveRecurringRuleOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveRecurringRuleSaved value)?  saved,TResult Function( SaveRecurringRuleRejected value)?  rejected,TResult Function( SaveRecurringRuleFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveRecurringRuleSaved() when saved != null:
return saved(_that);case SaveRecurringRuleRejected() when rejected != null:
return rejected(_that);case SaveRecurringRuleFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveRecurringRuleSaved value)  saved,required TResult Function( SaveRecurringRuleRejected value)  rejected,required TResult Function( SaveRecurringRuleFailed value)  failed,}){
final _that = this;
switch (_that) {
case SaveRecurringRuleSaved():
return saved(_that);case SaveRecurringRuleRejected():
return rejected(_that);case SaveRecurringRuleFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveRecurringRuleSaved value)?  saved,TResult? Function( SaveRecurringRuleRejected value)?  rejected,TResult? Function( SaveRecurringRuleFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SaveRecurringRuleSaved() when saved != null:
return saved(_that);case SaveRecurringRuleRejected() when rejected != null:
return rejected(_that);case SaveRecurringRuleFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int ruleId,  bool generationFailed)?  saved,TResult Function()?  rejected,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveRecurringRuleSaved() when saved != null:
return saved(_that.ruleId,_that.generationFailed);case SaveRecurringRuleRejected() when rejected != null:
return rejected();case SaveRecurringRuleFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int ruleId,  bool generationFailed)  saved,required TResult Function()  rejected,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case SaveRecurringRuleSaved():
return saved(_that.ruleId,_that.generationFailed);case SaveRecurringRuleRejected():
return rejected();case SaveRecurringRuleFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int ruleId,  bool generationFailed)?  saved,TResult? Function()?  rejected,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case SaveRecurringRuleSaved() when saved != null:
return saved(_that.ruleId,_that.generationFailed);case SaveRecurringRuleRejected() when rejected != null:
return rejected();case SaveRecurringRuleFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class SaveRecurringRuleSaved implements SaveRecurringRuleOutcome {
  const SaveRecurringRuleSaved(this.ruleId, this.generationFailed);
  

 final  int ruleId;
 final  bool generationFailed;

/// Create a copy of SaveRecurringRuleOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveRecurringRuleSavedCopyWith<SaveRecurringRuleSaved> get copyWith => _$SaveRecurringRuleSavedCopyWithImpl<SaveRecurringRuleSaved>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveRecurringRuleSaved&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.generationFailed, generationFailed) || other.generationFailed == generationFailed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,ruleId,generationFailed);
}

@override
String toString() {
    return 'SaveRecurringRuleOutcome.saved(ruleId: $ruleId, generationFailed: $generationFailed)';
}


}

/// @nodoc
abstract mixin class $SaveRecurringRuleSavedCopyWith<$Res> implements $SaveRecurringRuleOutcomeCopyWith<$Res> {
  factory $SaveRecurringRuleSavedCopyWith(SaveRecurringRuleSaved value, $Res Function(SaveRecurringRuleSaved) _then) = _$SaveRecurringRuleSavedCopyWithImpl;
@useResult
$Res call({
 int ruleId, bool generationFailed
});




}
/// @nodoc
class _$SaveRecurringRuleSavedCopyWithImpl<$Res>
    implements $SaveRecurringRuleSavedCopyWith<$Res> {
  _$SaveRecurringRuleSavedCopyWithImpl(this._self, this._then);

  final SaveRecurringRuleSaved _self;
  final $Res Function(SaveRecurringRuleSaved) _then;

/// Create a copy of SaveRecurringRuleOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ruleId = null,Object? generationFailed = null,}) {
  return _then(SaveRecurringRuleSaved(
null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as int,null == generationFailed ? _self.generationFailed : generationFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class SaveRecurringRuleRejected implements SaveRecurringRuleOutcome {
  const SaveRecurringRuleRejected();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveRecurringRuleRejected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveRecurringRuleOutcome.rejected()';
}


}




/// @nodoc


class SaveRecurringRuleFailed implements SaveRecurringRuleOutcome {
  const SaveRecurringRuleFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveRecurringRuleFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveRecurringRuleOutcome.failed()';
}


}




/// @nodoc
mixin _$ArchiveRecurringRuleOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveRecurringRuleOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveRecurringRuleOutcome()';
}


}

/// @nodoc
class $ArchiveRecurringRuleOutcomeCopyWith<$Res>  {
$ArchiveRecurringRuleOutcomeCopyWith(ArchiveRecurringRuleOutcome _, $Res Function(ArchiveRecurringRuleOutcome) __);
}


/// Adds pattern-matching-related methods to [ArchiveRecurringRuleOutcome].
extension ArchiveRecurringRuleOutcomePatterns on ArchiveRecurringRuleOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ArchiveRecurringRuleOk value)?  ok,TResult Function( ArchiveRecurringRuleFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ArchiveRecurringRuleOk() when ok != null:
return ok(_that);case ArchiveRecurringRuleFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ArchiveRecurringRuleOk value)  ok,required TResult Function( ArchiveRecurringRuleFailed value)  failed,}){
final _that = this;
switch (_that) {
case ArchiveRecurringRuleOk():
return ok(_that);case ArchiveRecurringRuleFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ArchiveRecurringRuleOk value)?  ok,TResult? Function( ArchiveRecurringRuleFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ArchiveRecurringRuleOk() when ok != null:
return ok(_that);case ArchiveRecurringRuleFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ArchiveRecurringRuleOk() when ok != null:
return ok();case ArchiveRecurringRuleFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case ArchiveRecurringRuleOk():
return ok();case ArchiveRecurringRuleFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case ArchiveRecurringRuleOk() when ok != null:
return ok();case ArchiveRecurringRuleFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class ArchiveRecurringRuleOk implements ArchiveRecurringRuleOutcome {
  const ArchiveRecurringRuleOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveRecurringRuleOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveRecurringRuleOutcome.ok()';
}


}




/// @nodoc


class ArchiveRecurringRuleFailed implements ArchiveRecurringRuleOutcome {
  const ArchiveRecurringRuleFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveRecurringRuleFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveRecurringRuleOutcome.failed()';
}


}




// dart format on
