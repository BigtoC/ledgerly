// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Transaction {

 int get id;/// Integer minor units. Scaling factor is `Currency.decimals`. Never
/// a double, not even for display. See PRD.md -> Money Storage Policy.
 int get amountMinorUnits;/// Original-transaction currency value object on the read side. Drift
/// column stays a `TEXT` FK to `currencies.code`.
 Currency get currency;/// FK -> `categories.id`. Type (expense/income) derives from the
/// linked category.
 int get categoryId;/// FK -> `accounts.id`.
 int get accountId;/// User-supplied transaction date.
 DateTime get date;/// Optional free text.
 String? get memo;/// Keypad expression that produced [amountMinorUnits] (e.g.
/// `3.5+10.5+11+3`), or null when the amount was typed directly.
 String? get amountFormula;/// Repository-populated at insert; immutable across updates (M3).
 DateTime get createdAt;/// Repository-populated at insert; refreshed on every update (M3).
 DateTime get updatedAt;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Transaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.amountMinorUnits, _this.amountMinorUnits) || other.amountMinorUnits == _this.amountMinorUnits)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.amountFormula, _this.amountFormula) || other.amountFormula == _this.amountFormula)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as Transaction;
  return Object.hash(runtimeType,_this.id,_this.amountMinorUnits,_this.currency,_this.categoryId,_this.accountId,_this.date,_this.memo,_this.amountFormula,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Transaction;
  return 'Transaction(id: ${_this.id}, amountMinorUnits: ${_this.amountMinorUnits}, currency: ${_this.currency}, categoryId: ${_this.categoryId}, accountId: ${_this.accountId}, date: ${_this.date}, memo: ${_this.memo}, amountFormula: ${_this.amountFormula}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 int id, int amountMinorUnits, Currency currency, int categoryId, int accountId, DateTime date, String? memo, String? amountFormula, DateTime createdAt, DateTime updatedAt
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = null,Object? accountId = null,Object? date = null,Object? memo = freezed,Object? amountFormula = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,amountFormula: freezed == amountFormula ? _self.amountFormula : amountFormula // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  DateTime date,  String? memo,  String? amountFormula,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.date,_that.memo,_that.amountFormula,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  DateTime date,  String? memo,  String? amountFormula,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.date,_that.memo,_that.amountFormula,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int amountMinorUnits,  Currency currency,  int categoryId,  int accountId,  DateTime date,  String? memo,  String? amountFormula,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.date,_that.memo,_that.amountFormula,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Transaction implements Transaction {
  const _Transaction({required this.id, required this.amountMinorUnits, required this.currency, required this.categoryId, required this.accountId, required this.date, this.memo, this.amountFormula, required this.createdAt, required this.updatedAt});
  

@override final  int id;
/// Integer minor units. Scaling factor is `Currency.decimals`. Never
/// a double, not even for display. See PRD.md -> Money Storage Policy.
@override final  int amountMinorUnits;
/// Original-transaction currency value object on the read side. Drift
/// column stays a `TEXT` FK to `currencies.code`.
@override final  Currency currency;
/// FK -> `categories.id`. Type (expense/income) derives from the
/// linked category.
@override final  int categoryId;
/// FK -> `accounts.id`.
@override final  int accountId;
/// User-supplied transaction date.
@override final  DateTime date;
/// Optional free text.
@override final  String? memo;
/// Keypad expression that produced [amountMinorUnits] (e.g.
/// `3.5+10.5+11+3`), or null when the amount was typed directly.
@override final  String? amountFormula;
/// Repository-populated at insert; immutable across updates (M3).
@override final  DateTime createdAt;
/// Repository-populated at insert; refreshed on every update (M3).
@override final  DateTime updatedAt;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.date, date) || other.date == date)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.amountFormula, amountFormula) || other.amountFormula == amountFormula)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,amountMinorUnits,currency,categoryId,accountId,date,memo,amountFormula,createdAt,updatedAt);
}

@override
String toString() {
    return 'Transaction(id: $id, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, date: $date, memo: $memo, amountFormula: $amountFormula, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 int id, int amountMinorUnits, Currency currency, int categoryId, int accountId, DateTime date, String? memo, String? amountFormula, DateTime createdAt, DateTime updatedAt
});


@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = null,Object? accountId = null,Object? date = null,Object? memo = freezed,Object? amountFormula = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,amountFormula: freezed == amountFormula ? _self.amountFormula : amountFormula // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Transaction
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
