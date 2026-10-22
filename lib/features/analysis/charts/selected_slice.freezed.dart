// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'selected_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SelectedSlice {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedSlice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SelectedSlice()';
}


}

/// @nodoc
class $SelectedSliceCopyWith<$Res>  {
$SelectedSliceCopyWith(SelectedSlice _, $Res Function(SelectedSlice) __);
}


/// Adds pattern-matching-related methods to [SelectedSlice].
extension SelectedSlicePatterns on SelectedSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SelectedCategorySlice value)?  category,TResult Function( SelectedAccountSlice value)?  account,TResult Function( SelectedCurrencySlice value)?  currency,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SelectedCategorySlice() when category != null:
return category(_that);case SelectedAccountSlice() when account != null:
return account(_that);case SelectedCurrencySlice() when currency != null:
return currency(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SelectedCategorySlice value)  category,required TResult Function( SelectedAccountSlice value)  account,required TResult Function( SelectedCurrencySlice value)  currency,}){
final _that = this;
switch (_that) {
case SelectedCategorySlice():
return category(_that);case SelectedAccountSlice():
return account(_that);case SelectedCurrencySlice():
return currency(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SelectedCategorySlice value)?  category,TResult? Function( SelectedAccountSlice value)?  account,TResult? Function( SelectedCurrencySlice value)?  currency,}){
final _that = this;
switch (_that) {
case SelectedCategorySlice() when category != null:
return category(_that);case SelectedAccountSlice() when account != null:
return account(_that);case SelectedCurrencySlice() when currency != null:
return currency(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int categoryId,  String? currencyCode)?  category,TResult Function( int accountId)?  account,TResult Function( String currencyCode)?  currency,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SelectedCategorySlice() when category != null:
return category(_that.categoryId,_that.currencyCode);case SelectedAccountSlice() when account != null:
return account(_that.accountId);case SelectedCurrencySlice() when currency != null:
return currency(_that.currencyCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int categoryId,  String? currencyCode)  category,required TResult Function( int accountId)  account,required TResult Function( String currencyCode)  currency,}) {final _that = this;
switch (_that) {
case SelectedCategorySlice():
return category(_that.categoryId,_that.currencyCode);case SelectedAccountSlice():
return account(_that.accountId);case SelectedCurrencySlice():
return currency(_that.currencyCode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int categoryId,  String? currencyCode)?  category,TResult? Function( int accountId)?  account,TResult? Function( String currencyCode)?  currency,}) {final _that = this;
switch (_that) {
case SelectedCategorySlice() when category != null:
return category(_that.categoryId,_that.currencyCode);case SelectedAccountSlice() when account != null:
return account(_that.accountId);case SelectedCurrencySlice() when currency != null:
return currency(_that.currencyCode);case _:
  return null;

}
}

}

/// @nodoc


class SelectedCategorySlice implements SelectedSlice {
  const SelectedCategorySlice(this.categoryId, {this.currencyCode});
  

 final  int categoryId;
 final  String? currencyCode;

/// Create a copy of SelectedSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectedCategorySliceCopyWith<SelectedCategorySlice> get copyWith => _$SelectedCategorySliceCopyWithImpl<SelectedCategorySlice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedCategorySlice&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,categoryId,currencyCode);
}

@override
String toString() {
    return 'SelectedSlice.category(categoryId: $categoryId, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class $SelectedCategorySliceCopyWith<$Res> implements $SelectedSliceCopyWith<$Res> {
  factory $SelectedCategorySliceCopyWith(SelectedCategorySlice value, $Res Function(SelectedCategorySlice) _then) = _$SelectedCategorySliceCopyWithImpl;
@useResult
$Res call({
 int categoryId, String? currencyCode
});




}
/// @nodoc
class _$SelectedCategorySliceCopyWithImpl<$Res>
    implements $SelectedCategorySliceCopyWith<$Res> {
  _$SelectedCategorySliceCopyWithImpl(this._self, this._then);

  final SelectedCategorySlice _self;
  final $Res Function(SelectedCategorySlice) _then;

/// Create a copy of SelectedSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? currencyCode = freezed,}) {
  return _then(SelectedCategorySlice(
null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,currencyCode: freezed == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SelectedAccountSlice implements SelectedSlice {
  const SelectedAccountSlice(this.accountId);
  

 final  int accountId;

/// Create a copy of SelectedSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectedAccountSliceCopyWith<SelectedAccountSlice> get copyWith => _$SelectedAccountSliceCopyWithImpl<SelectedAccountSlice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedAccountSlice&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accountId);
}

@override
String toString() {
    return 'SelectedSlice.account(accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $SelectedAccountSliceCopyWith<$Res> implements $SelectedSliceCopyWith<$Res> {
  factory $SelectedAccountSliceCopyWith(SelectedAccountSlice value, $Res Function(SelectedAccountSlice) _then) = _$SelectedAccountSliceCopyWithImpl;
@useResult
$Res call({
 int accountId
});




}
/// @nodoc
class _$SelectedAccountSliceCopyWithImpl<$Res>
    implements $SelectedAccountSliceCopyWith<$Res> {
  _$SelectedAccountSliceCopyWithImpl(this._self, this._then);

  final SelectedAccountSlice _self;
  final $Res Function(SelectedAccountSlice) _then;

/// Create a copy of SelectedSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accountId = null,}) {
  return _then(SelectedAccountSlice(
null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SelectedCurrencySlice implements SelectedSlice {
  const SelectedCurrencySlice(this.currencyCode);
  

 final  String currencyCode;

/// Create a copy of SelectedSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectedCurrencySliceCopyWith<SelectedCurrencySlice> get copyWith => _$SelectedCurrencySliceCopyWithImpl<SelectedCurrencySlice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectedCurrencySlice&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,currencyCode);
}

@override
String toString() {
    return 'SelectedSlice.currency(currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class $SelectedCurrencySliceCopyWith<$Res> implements $SelectedSliceCopyWith<$Res> {
  factory $SelectedCurrencySliceCopyWith(SelectedCurrencySlice value, $Res Function(SelectedCurrencySlice) _then) = _$SelectedCurrencySliceCopyWithImpl;
@useResult
$Res call({
 String currencyCode
});




}
/// @nodoc
class _$SelectedCurrencySliceCopyWithImpl<$Res>
    implements $SelectedCurrencySliceCopyWith<$Res> {
  _$SelectedCurrencySliceCopyWithImpl(this._self, this._then);

  final SelectedCurrencySlice _self;
  final $Res Function(SelectedCurrencySlice) _then;

/// Create a copy of SelectedSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? currencyCode = null,}) {
  return _then(SelectedCurrencySlice(
null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
