// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionFormState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransactionFormState()';
}


}

/// @nodoc
class $TransactionFormStateCopyWith<$Res>  {
$TransactionFormStateCopyWith(TransactionFormState _, $Res Function(TransactionFormState) __);
}


/// Adds pattern-matching-related methods to [TransactionFormState].
extension TransactionFormStatePatterns on TransactionFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TransactionFormLoading value)?  loading,TResult Function( TransactionFormEmpty value)?  empty,TResult Function( TransactionFormData value)?  data,TResult Function( TransactionFormError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that);case TransactionFormEmpty() when empty != null:
return empty(_that);case TransactionFormData() when data != null:
return data(_that);case TransactionFormError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TransactionFormLoading value)  loading,required TResult Function( TransactionFormEmpty value)  empty,required TResult Function( TransactionFormData value)  data,required TResult Function( TransactionFormError value)  error,}){
final _that = this;
switch (_that) {
case TransactionFormLoading():
return loading(_that);case TransactionFormEmpty():
return empty(_that);case TransactionFormData():
return data(_that);case TransactionFormError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TransactionFormLoading value)?  loading,TResult? Function( TransactionFormEmpty value)?  empty,TResult? Function( TransactionFormData value)?  data,TResult? Function( TransactionFormError value)?  error,}){
final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that);case TransactionFormEmpty() when empty != null:
return empty(_that);case TransactionFormData() when data != null:
return data(_that);case TransactionFormError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( TransactionFormEmptyReason reason)?  empty,TResult Function( int amountMinorUnits,  Account? selectedAccount,  Currency? displayCurrency,  bool currencyTouched,  Category? selectedCategory,  CategoryType pendingType,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  int? duplicateSourceId,  DateTime? originalCreatedAt,  int keypadRevision)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading();case TransactionFormEmpty() when empty != null:
return empty(_that.reason);case TransactionFormData() when data != null:
return data(_that.amountMinorUnits,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.pendingType,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.duplicateSourceId,_that.originalCreatedAt,_that.keypadRevision);case TransactionFormError() when error != null:
return error(_that.error,_that.stack);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( TransactionFormEmptyReason reason)  empty,required TResult Function( int amountMinorUnits,  Account? selectedAccount,  Currency? displayCurrency,  bool currencyTouched,  Category? selectedCategory,  CategoryType pendingType,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  int? duplicateSourceId,  DateTime? originalCreatedAt,  int keypadRevision)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case TransactionFormLoading():
return loading();case TransactionFormEmpty():
return empty(_that.reason);case TransactionFormData():
return data(_that.amountMinorUnits,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.pendingType,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.duplicateSourceId,_that.originalCreatedAt,_that.keypadRevision);case TransactionFormError():
return error(_that.error,_that.stack);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( TransactionFormEmptyReason reason)?  empty,TResult? Function( int amountMinorUnits,  Account? selectedAccount,  Currency? displayCurrency,  bool currencyTouched,  Category? selectedCategory,  CategoryType pendingType,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  int? duplicateSourceId,  DateTime? originalCreatedAt,  int keypadRevision)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading();case TransactionFormEmpty() when empty != null:
return empty(_that.reason);case TransactionFormData() when data != null:
return data(_that.amountMinorUnits,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.pendingType,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.duplicateSourceId,_that.originalCreatedAt,_that.keypadRevision);case TransactionFormError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class TransactionFormLoading extends TransactionFormState {
  const TransactionFormLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransactionFormState.loading()';
}


}




/// @nodoc


class TransactionFormEmpty extends TransactionFormState {
  const TransactionFormEmpty({required this.reason}): super._();
  

 final  TransactionFormEmptyReason reason;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormEmptyCopyWith<TransactionFormEmpty> get copyWith => _$TransactionFormEmptyCopyWithImpl<TransactionFormEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormEmpty&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'TransactionFormState.empty(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $TransactionFormEmptyCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormEmptyCopyWith(TransactionFormEmpty value, $Res Function(TransactionFormEmpty) _then) = _$TransactionFormEmptyCopyWithImpl;
@useResult
$Res call({
 TransactionFormEmptyReason reason
});




}
/// @nodoc
class _$TransactionFormEmptyCopyWithImpl<$Res>
    implements $TransactionFormEmptyCopyWith<$Res> {
  _$TransactionFormEmptyCopyWithImpl(this._self, this._then);

  final TransactionFormEmpty _self;
  final $Res Function(TransactionFormEmpty) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(TransactionFormEmpty(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as TransactionFormEmptyReason,
  ));
}


}

/// @nodoc


class TransactionFormData extends TransactionFormState {
  const TransactionFormData({required this.amountMinorUnits, required this.selectedAccount, required this.displayCurrency, required this.currencyTouched, required this.selectedCategory, required this.pendingType, required this.date, required this.memo, required this.isDirty, required this.isSaving, required this.isDeleting, required this.editingId, required this.duplicateSourceId, required this.originalCreatedAt, this.keypadRevision = 0}): super._();
  

/// Keypad-accumulated integer in the active currency's minor units.
 final  int amountMinorUnits;
/// `null` only during `noActiveAccount` recovery flows; in normal
/// `.data` states an account is always selected.
 final  Account? selectedAccount;
/// The transaction's currency. Seeds from `selectedAccount.currency` on
/// hydration, but can be independently overridden by the user via the
/// currency picker. Once the user has made a manual selection,
/// `currencyTouched` is `true` and account changes no longer re-seed it.
 final  Currency? displayCurrency;
/// `true` once the user has manually selected a currency via the picker.
/// When `false`, account changes re-seed `displayCurrency` from the
/// new account's currency. When `true`, `displayCurrency` is user-owned
/// and account changes only update `selectedAccount`.
 final  bool currencyTouched;
 final  Category? selectedCategory;
/// Drives the picker filter before category selection. After a
/// category is selected, `selectedCategory.type` is the source of
/// truth; `pendingType` only differs during the confirm-then-clear
/// flow that swaps types.
 final  CategoryType pendingType;
 final  DateTime date;
/// Free-form note. Empty string is valid; nullability is collapsed
/// to "" so the controller never has to decide between `null` and
/// `''` on every keystroke.
 final  String memo;
/// Becomes true on the first user-driven mutation after hydration.
 final  bool isDirty;
/// `true` between `save()` await-start and resolution.
 final  bool isSaving;
/// `true` between `deleteExisting()` await-start and resolution.
 final  bool isDeleting;
/// Edit-mode target id. `null` in Add and Duplicate.
 final  int? editingId;
/// Source-id when opened via duplicate. `null` in Add and Edit.
 final  int? duplicateSourceId;
/// Edit-mode original `createdAt`, preserved on update so the
/// repository contract (`save` keeps stored `createdAt`) is honored
/// even if the controller round-trips through copyWith.
 final  DateTime? originalCreatedAt;
/// Incremented on every keypad mutation — including expression-only
/// transitions that leave `amountMinorUnits` unchanged — so Riverpod
/// rebuilds the form whenever the display state changes.
@JsonKey() final  int keypadRevision;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormDataCopyWith<TransactionFormData> get copyWith => _$TransactionFormDataCopyWithImpl<TransactionFormData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormData&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.selectedAccount, selectedAccount) || other.selectedAccount == selectedAccount)&&(identical(other.displayCurrency, displayCurrency) || other.displayCurrency == displayCurrency)&&(identical(other.currencyTouched, currencyTouched) || other.currencyTouched == currencyTouched)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.pendingType, pendingType) || other.pendingType == pendingType)&&(identical(other.date, date) || other.date == date)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isDeleting, isDeleting) || other.isDeleting == isDeleting)&&(identical(other.editingId, editingId) || other.editingId == editingId)&&(identical(other.duplicateSourceId, duplicateSourceId) || other.duplicateSourceId == duplicateSourceId)&&(identical(other.originalCreatedAt, originalCreatedAt) || other.originalCreatedAt == originalCreatedAt)&&(identical(other.keypadRevision, keypadRevision) || other.keypadRevision == keypadRevision));
}


@override
int get hashCode => Object.hash(runtimeType,amountMinorUnits,selectedAccount,displayCurrency,currencyTouched,selectedCategory,pendingType,date,memo,isDirty,isSaving,isDeleting,editingId,duplicateSourceId,originalCreatedAt,keypadRevision);

@override
String toString() {
  return 'TransactionFormState.data(amountMinorUnits: $amountMinorUnits, selectedAccount: $selectedAccount, displayCurrency: $displayCurrency, currencyTouched: $currencyTouched, selectedCategory: $selectedCategory, pendingType: $pendingType, date: $date, memo: $memo, isDirty: $isDirty, isSaving: $isSaving, isDeleting: $isDeleting, editingId: $editingId, duplicateSourceId: $duplicateSourceId, originalCreatedAt: $originalCreatedAt, keypadRevision: $keypadRevision)';
}


}

/// @nodoc
abstract mixin class $TransactionFormDataCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormDataCopyWith(TransactionFormData value, $Res Function(TransactionFormData) _then) = _$TransactionFormDataCopyWithImpl;
@useResult
$Res call({
 int amountMinorUnits, Account? selectedAccount, Currency? displayCurrency, bool currencyTouched, Category? selectedCategory, CategoryType pendingType, DateTime date, String memo, bool isDirty, bool isSaving, bool isDeleting, int? editingId, int? duplicateSourceId, DateTime? originalCreatedAt, int keypadRevision
});


$AccountCopyWith<$Res>? get selectedAccount;$CurrencyCopyWith<$Res>? get displayCurrency;$CategoryCopyWith<$Res>? get selectedCategory;

}
/// @nodoc
class _$TransactionFormDataCopyWithImpl<$Res>
    implements $TransactionFormDataCopyWith<$Res> {
  _$TransactionFormDataCopyWithImpl(this._self, this._then);

  final TransactionFormData _self;
  final $Res Function(TransactionFormData) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amountMinorUnits = null,Object? selectedAccount = freezed,Object? displayCurrency = freezed,Object? currencyTouched = null,Object? selectedCategory = freezed,Object? pendingType = null,Object? date = null,Object? memo = null,Object? isDirty = null,Object? isSaving = null,Object? isDeleting = null,Object? editingId = freezed,Object? duplicateSourceId = freezed,Object? originalCreatedAt = freezed,Object? keypadRevision = null,}) {
  return _then(TransactionFormData(
amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,selectedAccount: freezed == selectedAccount ? _self.selectedAccount : selectedAccount // ignore: cast_nullable_to_non_nullable
as Account?,displayCurrency: freezed == displayCurrency ? _self.displayCurrency : displayCurrency // ignore: cast_nullable_to_non_nullable
as Currency?,currencyTouched: null == currencyTouched ? _self.currencyTouched : currencyTouched // ignore: cast_nullable_to_non_nullable
as bool,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as Category?,pendingType: null == pendingType ? _self.pendingType : pendingType // ignore: cast_nullable_to_non_nullable
as CategoryType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,memo: null == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isDeleting: null == isDeleting ? _self.isDeleting : isDeleting // ignore: cast_nullable_to_non_nullable
as bool,editingId: freezed == editingId ? _self.editingId : editingId // ignore: cast_nullable_to_non_nullable
as int?,duplicateSourceId: freezed == duplicateSourceId ? _self.duplicateSourceId : duplicateSourceId // ignore: cast_nullable_to_non_nullable
as int?,originalCreatedAt: freezed == originalCreatedAt ? _self.originalCreatedAt : originalCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,keypadRevision: null == keypadRevision ? _self.keypadRevision : keypadRevision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountCopyWith<$Res>? get selectedAccount {
    if (_self.selectedAccount == null) {
    return null;
  }

  return $AccountCopyWith<$Res>(_self.selectedAccount!, (value) {
    return _then(_self.copyWith(selectedAccount: value));
  });
}/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res>? get displayCurrency {
    if (_self.displayCurrency == null) {
    return null;
  }

  return $CurrencyCopyWith<$Res>(_self.displayCurrency!, (value) {
    return _then(_self.copyWith(displayCurrency: value));
  });
}/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get selectedCategory {
    if (_self.selectedCategory == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.selectedCategory!, (value) {
    return _then(_self.copyWith(selectedCategory: value));
  });
}
}

/// @nodoc


class TransactionFormError extends TransactionFormState {
  const TransactionFormError(this.error, this.stack): super._();
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormErrorCopyWith<TransactionFormError> get copyWith => _$TransactionFormErrorCopyWithImpl<TransactionFormError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'TransactionFormState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $TransactionFormErrorCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormErrorCopyWith(TransactionFormError value, $Res Function(TransactionFormError) _then) = _$TransactionFormErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$TransactionFormErrorCopyWithImpl<$Res>
    implements $TransactionFormErrorCopyWith<$Res> {
  _$TransactionFormErrorCopyWithImpl(this._self, this._then);

  final TransactionFormError _self;
  final $Res Function(TransactionFormError) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(TransactionFormError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
