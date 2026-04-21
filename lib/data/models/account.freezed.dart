// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Account {

 int get id;/// User-visible account name.
 String get name;/// FK -> `account_types.id`. NOT NULL.
 int get accountTypeId;/// Native currency value object on the read side. Drift column stays
/// a `TEXT` FK to `currencies.code`.
 Currency get currency;/// Integer minor units. Scaling factor is `Currency.decimals`. Never
/// a double. See PRD.md -> Money Storage Policy.
 int get openingBalanceMinorUnits;/// Icon-registry string key, or null. Never `IconData`.
 String? get icon;/// Palette index, or null. Never ARGB.
 int? get color;/// Order in pickers.
 int? get sortOrder;/// DB default `false`.
 bool get isArchived;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.accountTypeId, accountTypeId) || other.accountTypeId == accountTypeId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.openingBalanceMinorUnits, openingBalanceMinorUnits) || other.openingBalanceMinorUnits == openingBalanceMinorUnits)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,accountTypeId,currency,openingBalanceMinorUnits,icon,color,sortOrder,isArchived);

@override
String toString() {
  return 'Account(id: $id, name: $name, accountTypeId: $accountTypeId, currency: $currency, openingBalanceMinorUnits: $openingBalanceMinorUnits, icon: $icon, color: $color, sortOrder: $sortOrder, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
 int id, String name, int accountTypeId, Currency currency, int openingBalanceMinorUnits, String? icon, int? color, int? sortOrder, bool isArchived
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? accountTypeId = null,Object? currency = null,Object? openingBalanceMinorUnits = null,Object? icon = freezed,Object? color = freezed,Object? sortOrder = freezed,Object? isArchived = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,accountTypeId: null == accountTypeId ? _self.accountTypeId : accountTypeId // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,openingBalanceMinorUnits: null == openingBalanceMinorUnits ? _self.openingBalanceMinorUnits : openingBalanceMinorUnits // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Account value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Account value)  $default,){
final _that = this;
switch (_that) {
case _Account():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Account value)?  $default,){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int accountTypeId,  Currency currency,  int openingBalanceMinorUnits,  String? icon,  int? color,  int? sortOrder,  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.name,_that.accountTypeId,_that.currency,_that.openingBalanceMinorUnits,_that.icon,_that.color,_that.sortOrder,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int accountTypeId,  Currency currency,  int openingBalanceMinorUnits,  String? icon,  int? color,  int? sortOrder,  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _Account():
return $default(_that.id,_that.name,_that.accountTypeId,_that.currency,_that.openingBalanceMinorUnits,_that.icon,_that.color,_that.sortOrder,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int accountTypeId,  Currency currency,  int openingBalanceMinorUnits,  String? icon,  int? color,  int? sortOrder,  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.name,_that.accountTypeId,_that.currency,_that.openingBalanceMinorUnits,_that.icon,_that.color,_that.sortOrder,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc


class _Account implements Account {
  const _Account({required this.id, required this.name, required this.accountTypeId, required this.currency, this.openingBalanceMinorUnits = 0, this.icon, this.color, this.sortOrder, this.isArchived = false});
  

@override final  int id;
/// User-visible account name.
@override final  String name;
/// FK -> `account_types.id`. NOT NULL.
@override final  int accountTypeId;
/// Native currency value object on the read side. Drift column stays
/// a `TEXT` FK to `currencies.code`.
@override final  Currency currency;
/// Integer minor units. Scaling factor is `Currency.decimals`. Never
/// a double. See PRD.md -> Money Storage Policy.
@override@JsonKey() final  int openingBalanceMinorUnits;
/// Icon-registry string key, or null. Never `IconData`.
@override final  String? icon;
/// Palette index, or null. Never ARGB.
@override final  int? color;
/// Order in pickers.
@override final  int? sortOrder;
/// DB default `false`.
@override@JsonKey() final  bool isArchived;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.accountTypeId, accountTypeId) || other.accountTypeId == accountTypeId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.openingBalanceMinorUnits, openingBalanceMinorUnits) || other.openingBalanceMinorUnits == openingBalanceMinorUnits)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,accountTypeId,currency,openingBalanceMinorUnits,icon,color,sortOrder,isArchived);

@override
String toString() {
  return 'Account(id: $id, name: $name, accountTypeId: $accountTypeId, currency: $currency, openingBalanceMinorUnits: $openingBalanceMinorUnits, icon: $icon, color: $color, sortOrder: $sortOrder, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int accountTypeId, Currency currency, int openingBalanceMinorUnits, String? icon, int? color, int? sortOrder, bool isArchived
});


@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? accountTypeId = null,Object? currency = null,Object? openingBalanceMinorUnits = null,Object? icon = freezed,Object? color = freezed,Object? sortOrder = freezed,Object? isArchived = null,}) {
  return _then(_Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,accountTypeId: null == accountTypeId ? _self.accountTypeId : accountTypeId // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,openingBalanceMinorUnits: null == openingBalanceMinorUnits ? _self.openingBalanceMinorUnits : openingBalanceMinorUnits // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Account
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
