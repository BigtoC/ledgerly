// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveTransactionOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveTransactionOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveTransactionOutcome()';
}


}

/// @nodoc
class $SaveTransactionOutcomeCopyWith<$Res>  {
$SaveTransactionOutcomeCopyWith(SaveTransactionOutcome _, $Res Function(SaveTransactionOutcome) __);
}


/// Adds pattern-matching-related methods to [SaveTransactionOutcome].
extension SaveTransactionOutcomePatterns on SaveTransactionOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveTransactionSaved value)?  saved,TResult Function( SaveTransactionInvalid value)?  invalid,TResult Function( SaveTransactionFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveTransactionSaved() when saved != null:
return saved(_that);case SaveTransactionInvalid() when invalid != null:
return invalid(_that);case SaveTransactionFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveTransactionSaved value)  saved,required TResult Function( SaveTransactionInvalid value)  invalid,required TResult Function( SaveTransactionFailed value)  failed,}){
final _that = this;
switch (_that) {
case SaveTransactionSaved():
return saved(_that);case SaveTransactionInvalid():
return invalid(_that);case SaveTransactionFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveTransactionSaved value)?  saved,TResult? Function( SaveTransactionInvalid value)?  invalid,TResult? Function( SaveTransactionFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SaveTransactionSaved() when saved != null:
return saved(_that);case SaveTransactionInvalid() when invalid != null:
return invalid(_that);case SaveTransactionFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Transaction transaction)?  saved,TResult Function()?  invalid,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveTransactionSaved() when saved != null:
return saved(_that.transaction);case SaveTransactionInvalid() when invalid != null:
return invalid();case SaveTransactionFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Transaction transaction)  saved,required TResult Function()  invalid,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case SaveTransactionSaved():
return saved(_that.transaction);case SaveTransactionInvalid():
return invalid();case SaveTransactionFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Transaction transaction)?  saved,TResult? Function()?  invalid,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case SaveTransactionSaved() when saved != null:
return saved(_that.transaction);case SaveTransactionInvalid() when invalid != null:
return invalid();case SaveTransactionFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class SaveTransactionSaved implements SaveTransactionOutcome {
  const SaveTransactionSaved(this.transaction);
  

 final  Transaction transaction;

/// Create a copy of SaveTransactionOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveTransactionSavedCopyWith<SaveTransactionSaved> get copyWith => _$SaveTransactionSavedCopyWithImpl<SaveTransactionSaved>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveTransactionSaved&&(identical(other.transaction, transaction) || other.transaction == transaction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,transaction);
}

@override
String toString() {
    return 'SaveTransactionOutcome.saved(transaction: $transaction)';
}


}

/// @nodoc
abstract mixin class $SaveTransactionSavedCopyWith<$Res> implements $SaveTransactionOutcomeCopyWith<$Res> {
  factory $SaveTransactionSavedCopyWith(SaveTransactionSaved value, $Res Function(SaveTransactionSaved) _then) = _$SaveTransactionSavedCopyWithImpl;
@useResult
$Res call({
 Transaction transaction
});


$TransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class _$SaveTransactionSavedCopyWithImpl<$Res>
    implements $SaveTransactionSavedCopyWith<$Res> {
  _$SaveTransactionSavedCopyWithImpl(this._self, this._then);

  final SaveTransactionSaved _self;
  final $Res Function(SaveTransactionSaved) _then;

/// Create a copy of SaveTransactionOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transaction = null,}) {
  return _then(SaveTransactionSaved(
null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as Transaction,
  ));
}

/// Create a copy of SaveTransactionOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res> get transaction {
  
  return $TransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}

/// @nodoc


class SaveTransactionInvalid implements SaveTransactionOutcome {
  const SaveTransactionInvalid();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveTransactionInvalid);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveTransactionOutcome.invalid()';
}


}




/// @nodoc


class SaveTransactionFailed implements SaveTransactionOutcome {
  const SaveTransactionFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveTransactionFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveTransactionOutcome.failed()';
}


}




/// @nodoc
mixin _$DeleteTransactionOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTransactionOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteTransactionOutcome()';
}


}

/// @nodoc
class $DeleteTransactionOutcomeCopyWith<$Res>  {
$DeleteTransactionOutcomeCopyWith(DeleteTransactionOutcome _, $Res Function(DeleteTransactionOutcome) __);
}


/// Adds pattern-matching-related methods to [DeleteTransactionOutcome].
extension DeleteTransactionOutcomePatterns on DeleteTransactionOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteTransactionDeleted value)?  deleted,TResult Function( DeleteTransactionNotFound value)?  notFound,TResult Function( DeleteTransactionIgnored value)?  ignored,TResult Function( DeleteTransactionFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteTransactionDeleted() when deleted != null:
return deleted(_that);case DeleteTransactionNotFound() when notFound != null:
return notFound(_that);case DeleteTransactionIgnored() when ignored != null:
return ignored(_that);case DeleteTransactionFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteTransactionDeleted value)  deleted,required TResult Function( DeleteTransactionNotFound value)  notFound,required TResult Function( DeleteTransactionIgnored value)  ignored,required TResult Function( DeleteTransactionFailed value)  failed,}){
final _that = this;
switch (_that) {
case DeleteTransactionDeleted():
return deleted(_that);case DeleteTransactionNotFound():
return notFound(_that);case DeleteTransactionIgnored():
return ignored(_that);case DeleteTransactionFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteTransactionDeleted value)?  deleted,TResult? Function( DeleteTransactionNotFound value)?  notFound,TResult? Function( DeleteTransactionIgnored value)?  ignored,TResult? Function( DeleteTransactionFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DeleteTransactionDeleted() when deleted != null:
return deleted(_that);case DeleteTransactionNotFound() when notFound != null:
return notFound(_that);case DeleteTransactionIgnored() when ignored != null:
return ignored(_that);case DeleteTransactionFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  deleted,TResult Function()?  notFound,TResult Function()?  ignored,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeleteTransactionDeleted() when deleted != null:
return deleted();case DeleteTransactionNotFound() when notFound != null:
return notFound();case DeleteTransactionIgnored() when ignored != null:
return ignored();case DeleteTransactionFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  deleted,required TResult Function()  notFound,required TResult Function()  ignored,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case DeleteTransactionDeleted():
return deleted();case DeleteTransactionNotFound():
return notFound();case DeleteTransactionIgnored():
return ignored();case DeleteTransactionFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  deleted,TResult? Function()?  notFound,TResult? Function()?  ignored,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case DeleteTransactionDeleted() when deleted != null:
return deleted();case DeleteTransactionNotFound() when notFound != null:
return notFound();case DeleteTransactionIgnored() when ignored != null:
return ignored();case DeleteTransactionFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class DeleteTransactionDeleted implements DeleteTransactionOutcome {
  const DeleteTransactionDeleted();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTransactionDeleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteTransactionOutcome.deleted()';
}


}




/// @nodoc


class DeleteTransactionNotFound implements DeleteTransactionOutcome {
  const DeleteTransactionNotFound();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTransactionNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteTransactionOutcome.notFound()';
}


}




/// @nodoc


class DeleteTransactionIgnored implements DeleteTransactionOutcome {
  const DeleteTransactionIgnored();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTransactionIgnored);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteTransactionOutcome.ignored()';
}


}




/// @nodoc


class DeleteTransactionFailed implements DeleteTransactionOutcome {
  const DeleteTransactionFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTransactionFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteTransactionOutcome.failed()';
}


}




/// @nodoc
mixin _$DraftSubmissionOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftSubmissionOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DraftSubmissionOutcome()';
}


}

/// @nodoc
class $DraftSubmissionOutcomeCopyWith<$Res>  {
$DraftSubmissionOutcomeCopyWith(DraftSubmissionOutcome _, $Res Function(DraftSubmissionOutcome) __);
}


/// Adds pattern-matching-related methods to [DraftSubmissionOutcome].
extension DraftSubmissionOutcomePatterns on DraftSubmissionOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DraftSubmissionOk value)?  ok,TResult Function( DraftSubmissionIgnored value)?  ignored,TResult Function( DraftSubmissionFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DraftSubmissionOk() when ok != null:
return ok(_that);case DraftSubmissionIgnored() when ignored != null:
return ignored(_that);case DraftSubmissionFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DraftSubmissionOk value)  ok,required TResult Function( DraftSubmissionIgnored value)  ignored,required TResult Function( DraftSubmissionFailed value)  failed,}){
final _that = this;
switch (_that) {
case DraftSubmissionOk():
return ok(_that);case DraftSubmissionIgnored():
return ignored(_that);case DraftSubmissionFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DraftSubmissionOk value)?  ok,TResult? Function( DraftSubmissionIgnored value)?  ignored,TResult? Function( DraftSubmissionFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DraftSubmissionOk() when ok != null:
return ok(_that);case DraftSubmissionIgnored() when ignored != null:
return ignored(_that);case DraftSubmissionFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ShoppingListEditResult result)?  ok,TResult Function()?  ignored,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DraftSubmissionOk() when ok != null:
return ok(_that.result);case DraftSubmissionIgnored() when ignored != null:
return ignored();case DraftSubmissionFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ShoppingListEditResult result)  ok,required TResult Function()  ignored,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case DraftSubmissionOk():
return ok(_that.result);case DraftSubmissionIgnored():
return ignored();case DraftSubmissionFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ShoppingListEditResult result)?  ok,TResult? Function()?  ignored,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case DraftSubmissionOk() when ok != null:
return ok(_that.result);case DraftSubmissionIgnored() when ignored != null:
return ignored();case DraftSubmissionFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class DraftSubmissionOk implements DraftSubmissionOutcome {
  const DraftSubmissionOk(this.result);
  

 final  ShoppingListEditResult result;

/// Create a copy of DraftSubmissionOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftSubmissionOkCopyWith<DraftSubmissionOk> get copyWith => _$DraftSubmissionOkCopyWithImpl<DraftSubmissionOk>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftSubmissionOk&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,result);
}

@override
String toString() {
    return 'DraftSubmissionOutcome.ok(result: $result)';
}


}

/// @nodoc
abstract mixin class $DraftSubmissionOkCopyWith<$Res> implements $DraftSubmissionOutcomeCopyWith<$Res> {
  factory $DraftSubmissionOkCopyWith(DraftSubmissionOk value, $Res Function(DraftSubmissionOk) _then) = _$DraftSubmissionOkCopyWithImpl;
@useResult
$Res call({
 ShoppingListEditResult result
});




}
/// @nodoc
class _$DraftSubmissionOkCopyWithImpl<$Res>
    implements $DraftSubmissionOkCopyWith<$Res> {
  _$DraftSubmissionOkCopyWithImpl(this._self, this._then);

  final DraftSubmissionOk _self;
  final $Res Function(DraftSubmissionOk) _then;

/// Create a copy of DraftSubmissionOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(DraftSubmissionOk(
null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ShoppingListEditResult,
  ));
}


}

/// @nodoc


class DraftSubmissionIgnored implements DraftSubmissionOutcome {
  const DraftSubmissionIgnored();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftSubmissionIgnored);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DraftSubmissionOutcome.ignored()';
}


}




/// @nodoc


class DraftSubmissionFailed implements DraftSubmissionOutcome {
  const DraftSubmissionFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftSubmissionFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DraftSubmissionOutcome.failed()';
}


}




/// @nodoc
mixin _$CategoryChipTapOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryChipTapOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CategoryChipTapOutcome()';
}


}

/// @nodoc
class $CategoryChipTapOutcomeCopyWith<$Res>  {
$CategoryChipTapOutcomeCopyWith(CategoryChipTapOutcome _, $Res Function(CategoryChipTapOutcome) __);
}


/// Adds pattern-matching-related methods to [CategoryChipTapOutcome].
extension CategoryChipTapOutcomePatterns on CategoryChipTapOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CategoryChipTapOpenPicker value)?  openPicker,TResult Function( CategoryChipTapManageCategories value)?  manageCategories,TResult Function( CategoryChipTapFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CategoryChipTapOpenPicker() when openPicker != null:
return openPicker(_that);case CategoryChipTapManageCategories() when manageCategories != null:
return manageCategories(_that);case CategoryChipTapFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CategoryChipTapOpenPicker value)  openPicker,required TResult Function( CategoryChipTapManageCategories value)  manageCategories,required TResult Function( CategoryChipTapFailed value)  failed,}){
final _that = this;
switch (_that) {
case CategoryChipTapOpenPicker():
return openPicker(_that);case CategoryChipTapManageCategories():
return manageCategories(_that);case CategoryChipTapFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CategoryChipTapOpenPicker value)?  openPicker,TResult? Function( CategoryChipTapManageCategories value)?  manageCategories,TResult? Function( CategoryChipTapFailed value)?  failed,}){
final _that = this;
switch (_that) {
case CategoryChipTapOpenPicker() when openPicker != null:
return openPicker(_that);case CategoryChipTapManageCategories() when manageCategories != null:
return manageCategories(_that);case CategoryChipTapFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  openPicker,TResult Function()?  manageCategories,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CategoryChipTapOpenPicker() when openPicker != null:
return openPicker();case CategoryChipTapManageCategories() when manageCategories != null:
return manageCategories();case CategoryChipTapFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  openPicker,required TResult Function()  manageCategories,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case CategoryChipTapOpenPicker():
return openPicker();case CategoryChipTapManageCategories():
return manageCategories();case CategoryChipTapFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  openPicker,TResult? Function()?  manageCategories,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case CategoryChipTapOpenPicker() when openPicker != null:
return openPicker();case CategoryChipTapManageCategories() when manageCategories != null:
return manageCategories();case CategoryChipTapFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class CategoryChipTapOpenPicker implements CategoryChipTapOutcome {
  const CategoryChipTapOpenPicker();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryChipTapOpenPicker);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CategoryChipTapOutcome.openPicker()';
}


}




/// @nodoc


class CategoryChipTapManageCategories implements CategoryChipTapOutcome {
  const CategoryChipTapManageCategories();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryChipTapManageCategories);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CategoryChipTapOutcome.manageCategories()';
}


}




/// @nodoc


class CategoryChipTapFailed implements CategoryChipTapOutcome {
  const CategoryChipTapFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryChipTapFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CategoryChipTapOutcome.failed()';
}


}




/// @nodoc
mixin _$TransactionFormState {

/// Discriminates which entry point opened the form so widgets can derive
/// titles, CTAs, and recovery behavior directly from state.
 TransactionFormMode get formMode;
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormStateCopyWith<TransactionFormState> get copyWith => _$TransactionFormStateCopyWithImpl<TransactionFormState>(this as TransactionFormState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionFormState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormState&&(identical(other.formMode, _this.formMode) || other.formMode == _this.formMode));
}


@override
int get hashCode {
  final _this = this as TransactionFormState;
  return Object.hash(runtimeType,_this.formMode);
}

@override
String toString() {
  final _this = this as TransactionFormState;
  return 'TransactionFormState(formMode: ${_this.formMode})';
}


}

/// @nodoc
abstract mixin class $TransactionFormStateCopyWith<$Res>  {
  factory $TransactionFormStateCopyWith(TransactionFormState value, $Res Function(TransactionFormState) _then) = _$TransactionFormStateCopyWithImpl;
@useResult
$Res call({
 TransactionFormMode formMode
});




}
/// @nodoc
class _$TransactionFormStateCopyWithImpl<$Res>
    implements $TransactionFormStateCopyWith<$Res> {
  _$TransactionFormStateCopyWithImpl(this._self, this._then);

  final TransactionFormState _self;
  final $Res Function(TransactionFormState) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? formMode = null,}) {
  return _then(_self.copyWith(
formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,
  ));
}

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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TransactionFormMode formMode)?  loading,TResult Function( TransactionFormEmptyReason reason,  TransactionFormMode formMode)?  empty,TResult Function( TransactionFormMode formMode,  int amountMinorUnits,  KeypadState keypad,  Account selectedAccount,  Currency displayCurrency,  bool currencyTouched,  Category? selectedCategory,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  DateTime? originalCreatedAt,  int? shoppingListItemId,  TransactionFormSubmissionAction submissionAction)?  data,TResult Function( Object error,  StackTrace stack,  TransactionFormMode formMode)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that.formMode);case TransactionFormEmpty() when empty != null:
return empty(_that.reason,_that.formMode);case TransactionFormData() when data != null:
return data(_that.formMode,_that.amountMinorUnits,_that.keypad,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.originalCreatedAt,_that.shoppingListItemId,_that.submissionAction);case TransactionFormError() when error != null:
return error(_that.error,_that.stack,_that.formMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TransactionFormMode formMode)  loading,required TResult Function( TransactionFormEmptyReason reason,  TransactionFormMode formMode)  empty,required TResult Function( TransactionFormMode formMode,  int amountMinorUnits,  KeypadState keypad,  Account selectedAccount,  Currency displayCurrency,  bool currencyTouched,  Category? selectedCategory,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  DateTime? originalCreatedAt,  int? shoppingListItemId,  TransactionFormSubmissionAction submissionAction)  data,required TResult Function( Object error,  StackTrace stack,  TransactionFormMode formMode)  error,}) {final _that = this;
switch (_that) {
case TransactionFormLoading():
return loading(_that.formMode);case TransactionFormEmpty():
return empty(_that.reason,_that.formMode);case TransactionFormData():
return data(_that.formMode,_that.amountMinorUnits,_that.keypad,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.originalCreatedAt,_that.shoppingListItemId,_that.submissionAction);case TransactionFormError():
return error(_that.error,_that.stack,_that.formMode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TransactionFormMode formMode)?  loading,TResult? Function( TransactionFormEmptyReason reason,  TransactionFormMode formMode)?  empty,TResult? Function( TransactionFormMode formMode,  int amountMinorUnits,  KeypadState keypad,  Account selectedAccount,  Currency displayCurrency,  bool currencyTouched,  Category? selectedCategory,  DateTime date,  String memo,  bool isDirty,  bool isSaving,  bool isDeleting,  int? editingId,  DateTime? originalCreatedAt,  int? shoppingListItemId,  TransactionFormSubmissionAction submissionAction)?  data,TResult? Function( Object error,  StackTrace stack,  TransactionFormMode formMode)?  error,}) {final _that = this;
switch (_that) {
case TransactionFormLoading() when loading != null:
return loading(_that.formMode);case TransactionFormEmpty() when empty != null:
return empty(_that.reason,_that.formMode);case TransactionFormData() when data != null:
return data(_that.formMode,_that.amountMinorUnits,_that.keypad,_that.selectedAccount,_that.displayCurrency,_that.currencyTouched,_that.selectedCategory,_that.date,_that.memo,_that.isDirty,_that.isSaving,_that.isDeleting,_that.editingId,_that.originalCreatedAt,_that.shoppingListItemId,_that.submissionAction);case TransactionFormError() when error != null:
return error(_that.error,_that.stack,_that.formMode);case _:
  return null;

}
}

}

/// @nodoc


class TransactionFormLoading extends TransactionFormState {
  const TransactionFormLoading({this.formMode = const AddTransactionMode()}): super._();
  

@override@JsonKey() final  TransactionFormMode formMode;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormLoadingCopyWith<TransactionFormLoading> get copyWith => _$TransactionFormLoadingCopyWithImpl<TransactionFormLoading>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormLoading&&(identical(other.formMode, formMode) || other.formMode == formMode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,formMode);
}

@override
String toString() {
    return 'TransactionFormState.loading(formMode: $formMode)';
}


}

/// @nodoc
abstract mixin class $TransactionFormLoadingCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormLoadingCopyWith(TransactionFormLoading value, $Res Function(TransactionFormLoading) _then) = _$TransactionFormLoadingCopyWithImpl;
@override @useResult
$Res call({
 TransactionFormMode formMode
});




}
/// @nodoc
class _$TransactionFormLoadingCopyWithImpl<$Res>
    implements $TransactionFormLoadingCopyWith<$Res> {
  _$TransactionFormLoadingCopyWithImpl(this._self, this._then);

  final TransactionFormLoading _self;
  final $Res Function(TransactionFormLoading) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? formMode = null,}) {
  return _then(TransactionFormLoading(
formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,
  ));
}


}

/// @nodoc


class TransactionFormEmpty extends TransactionFormState {
  const TransactionFormEmpty({required this.reason, this.formMode = const AddTransactionMode()}): super._();
  

 final  TransactionFormEmptyReason reason;
@override@JsonKey() final  TransactionFormMode formMode;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormEmptyCopyWith<TransactionFormEmpty> get copyWith => _$TransactionFormEmptyCopyWithImpl<TransactionFormEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormEmpty&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.formMode, formMode) || other.formMode == formMode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason,formMode);
}

@override
String toString() {
    return 'TransactionFormState.empty(reason: $reason, formMode: $formMode)';
}


}

/// @nodoc
abstract mixin class $TransactionFormEmptyCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormEmptyCopyWith(TransactionFormEmpty value, $Res Function(TransactionFormEmpty) _then) = _$TransactionFormEmptyCopyWithImpl;
@override @useResult
$Res call({
 TransactionFormEmptyReason reason, TransactionFormMode formMode
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
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? formMode = null,}) {
  return _then(TransactionFormEmpty(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as TransactionFormEmptyReason,formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,
  ));
}


}

/// @nodoc


class TransactionFormData extends TransactionFormState {
  const TransactionFormData({required this.formMode, required this.amountMinorUnits, required this.keypad, required this.selectedAccount, required this.displayCurrency, required this.currencyTouched, required this.selectedCategory, required this.date, required this.memo, this.isDirty = false, this.isSaving = false, this.isDeleting = false, this.editingId, this.originalCreatedAt, this.shoppingListItemId, this.submissionAction = TransactionFormSubmissionAction.none}): super._();
  

/// Discriminates which entry point opened the form so widgets can derive
/// titles, CTAs, and recovery behavior directly from state.
@override final  TransactionFormMode formMode;
/// Keypad-accumulated integer in the active currency's minor units.
 final  int amountMinorUnits;
/// Full calculator snapshot used by the amount display and by widgets that
/// need to know whether a currency/account change would discard input.
 final  KeypadState keypad;
 final  Account selectedAccount;
/// The transaction's currency. Seeds from `selectedAccount.currency` on
/// hydration, but can be independently overridden by the user via the
/// currency picker. Once the user has made a manual selection,
/// `currencyTouched` is `true` and account changes no longer re-seed it.
 final  Currency displayCurrency;
/// `true` once the user has manually selected a currency via the picker.
/// When `false`, account changes re-seed `displayCurrency` from the
/// new account's currency. When `true`, `displayCurrency` is user-owned
/// and account changes only update `selectedAccount`.
 final  bool currencyTouched;
 final  Category? selectedCategory;
 final  DateTime date;
/// Free-form note. Empty string is valid; nullability is collapsed
/// to "" so the controller never has to decide between `null` and
/// `''` on every keystroke.
 final  String memo;
/// Becomes true on the first user-driven mutation after hydration.
@JsonKey() final  bool isDirty;
/// `true` between `save()` await-start and resolution.
@JsonKey() final  bool isSaving;
/// `true` between `deleteExisting()` await-start and resolution.
@JsonKey() final  bool isDeleting;
/// Edit-mode target id. `null` in Add.
 final  int? editingId;
/// Edit-mode original `createdAt`, preserved on update so the
/// repository contract (`save` keeps stored `createdAt`) is honored
/// even if the controller round-trips through copyWith.
 final  DateTime? originalCreatedAt;
/// Non-null only in [EditShoppingListDraftMode]; stores the id of the
/// draft being edited so `saveDraft` and `convertDraft` can reference it.
 final  int? shoppingListItemId;
/// Tracks which async submission is currently in-flight. Used to
/// disable all CTAs and show a progress indicator on the active button.
@JsonKey() final  TransactionFormSubmissionAction submissionAction;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormDataCopyWith<TransactionFormData> get copyWith => _$TransactionFormDataCopyWithImpl<TransactionFormData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormData&&(identical(other.formMode, formMode) || other.formMode == formMode)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.keypad, keypad) || other.keypad == keypad)&&(identical(other.selectedAccount, selectedAccount) || other.selectedAccount == selectedAccount)&&(identical(other.displayCurrency, displayCurrency) || other.displayCurrency == displayCurrency)&&(identical(other.currencyTouched, currencyTouched) || other.currencyTouched == currencyTouched)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.date, date) || other.date == date)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isDeleting, isDeleting) || other.isDeleting == isDeleting)&&(identical(other.editingId, editingId) || other.editingId == editingId)&&(identical(other.originalCreatedAt, originalCreatedAt) || other.originalCreatedAt == originalCreatedAt)&&(identical(other.shoppingListItemId, shoppingListItemId) || other.shoppingListItemId == shoppingListItemId)&&(identical(other.submissionAction, submissionAction) || other.submissionAction == submissionAction));
}


@override
int get hashCode {
    return Object.hash(runtimeType,formMode,amountMinorUnits,keypad,selectedAccount,displayCurrency,currencyTouched,selectedCategory,date,memo,isDirty,isSaving,isDeleting,editingId,originalCreatedAt,shoppingListItemId,submissionAction);
}

@override
String toString() {
    return 'TransactionFormState.data(formMode: $formMode, amountMinorUnits: $amountMinorUnits, keypad: $keypad, selectedAccount: $selectedAccount, displayCurrency: $displayCurrency, currencyTouched: $currencyTouched, selectedCategory: $selectedCategory, date: $date, memo: $memo, isDirty: $isDirty, isSaving: $isSaving, isDeleting: $isDeleting, editingId: $editingId, originalCreatedAt: $originalCreatedAt, shoppingListItemId: $shoppingListItemId, submissionAction: $submissionAction)';
}


}

/// @nodoc
abstract mixin class $TransactionFormDataCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormDataCopyWith(TransactionFormData value, $Res Function(TransactionFormData) _then) = _$TransactionFormDataCopyWithImpl;
@override @useResult
$Res call({
 TransactionFormMode formMode, int amountMinorUnits, KeypadState keypad, Account selectedAccount, Currency displayCurrency, bool currencyTouched, Category? selectedCategory, DateTime date, String memo, bool isDirty, bool isSaving, bool isDeleting, int? editingId, DateTime? originalCreatedAt, int? shoppingListItemId, TransactionFormSubmissionAction submissionAction
});


$AccountCopyWith<$Res> get selectedAccount;$CurrencyCopyWith<$Res> get displayCurrency;$CategoryCopyWith<$Res>? get selectedCategory;

}
/// @nodoc
class _$TransactionFormDataCopyWithImpl<$Res>
    implements $TransactionFormDataCopyWith<$Res> {
  _$TransactionFormDataCopyWithImpl(this._self, this._then);

  final TransactionFormData _self;
  final $Res Function(TransactionFormData) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? formMode = null,Object? amountMinorUnits = null,Object? keypad = null,Object? selectedAccount = null,Object? displayCurrency = null,Object? currencyTouched = null,Object? selectedCategory = freezed,Object? date = null,Object? memo = null,Object? isDirty = null,Object? isSaving = null,Object? isDeleting = null,Object? editingId = freezed,Object? originalCreatedAt = freezed,Object? shoppingListItemId = freezed,Object? submissionAction = null,}) {
  return _then(TransactionFormData(
formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,keypad: null == keypad ? _self.keypad : keypad // ignore: cast_nullable_to_non_nullable
as KeypadState,selectedAccount: null == selectedAccount ? _self.selectedAccount : selectedAccount // ignore: cast_nullable_to_non_nullable
as Account,displayCurrency: null == displayCurrency ? _self.displayCurrency : displayCurrency // ignore: cast_nullable_to_non_nullable
as Currency,currencyTouched: null == currencyTouched ? _self.currencyTouched : currencyTouched // ignore: cast_nullable_to_non_nullable
as bool,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as Category?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,memo: null == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isDeleting: null == isDeleting ? _self.isDeleting : isDeleting // ignore: cast_nullable_to_non_nullable
as bool,editingId: freezed == editingId ? _self.editingId : editingId // ignore: cast_nullable_to_non_nullable
as int?,originalCreatedAt: freezed == originalCreatedAt ? _self.originalCreatedAt : originalCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,shoppingListItemId: freezed == shoppingListItemId ? _self.shoppingListItemId : shoppingListItemId // ignore: cast_nullable_to_non_nullable
as int?,submissionAction: null == submissionAction ? _self.submissionAction : submissionAction // ignore: cast_nullable_to_non_nullable
as TransactionFormSubmissionAction,
  ));
}

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountCopyWith<$Res> get selectedAccount {
  
  return $AccountCopyWith<$Res>(_self.selectedAccount, (value) {
    return _then(_self.copyWith(selectedAccount: value));
  });
}/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get displayCurrency {
  
  return $CurrencyCopyWith<$Res>(_self.displayCurrency, (value) {
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
  const TransactionFormError(this.error, this.stack, {this.formMode = const AddTransactionMode()}): super._();
  

 final  Object error;
 final  StackTrace stack;
@override@JsonKey() final  TransactionFormMode formMode;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormErrorCopyWith<TransactionFormError> get copyWith => _$TransactionFormErrorCopyWithImpl<TransactionFormError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack)&&(identical(other.formMode, formMode) || other.formMode == formMode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack,formMode);
}

@override
String toString() {
    return 'TransactionFormState.error(error: $error, stack: $stack, formMode: $formMode)';
}


}

/// @nodoc
abstract mixin class $TransactionFormErrorCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory $TransactionFormErrorCopyWith(TransactionFormError value, $Res Function(TransactionFormError) _then) = _$TransactionFormErrorCopyWithImpl;
@override @useResult
$Res call({
 Object error, StackTrace stack, TransactionFormMode formMode
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
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,Object? formMode = null,}) {
  return _then(TransactionFormError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,formMode: null == formMode ? _self.formMode : formMode // ignore: cast_nullable_to_non_nullable
as TransactionFormMode,
  ));
}


}

// dart format on
