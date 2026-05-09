// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_search_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategorySearchDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySearchDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategorySearchDetailState()';
}


}

/// @nodoc
class $CategorySearchDetailStateCopyWith<$Res>  {
$CategorySearchDetailStateCopyWith(CategorySearchDetailState _, $Res Function(CategorySearchDetailState) __);
}


/// Adds pattern-matching-related methods to [CategorySearchDetailState].
extension CategorySearchDetailStatePatterns on CategorySearchDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DetailLoading value)?  loading,TResult Function( DetailData value)?  data,TResult Function( DetailEmpty value)?  empty,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading(_that);case DetailData() when data != null:
return data(_that);case DetailEmpty() when empty != null:
return empty(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DetailLoading value)  loading,required TResult Function( DetailData value)  data,required TResult Function( DetailEmpty value)  empty,}){
final _that = this;
switch (_that) {
case DetailLoading():
return loading(_that);case DetailData():
return data(_that);case DetailEmpty():
return empty(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DetailLoading value)?  loading,TResult? Function( DetailData value)?  data,TResult? Function( DetailEmpty value)?  empty,}){
final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading(_that);case DetailData() when data != null:
return data(_that);case DetailEmpty() when empty != null:
return empty(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<DatedTransactionGroup> days,  int overallSumMinorUnits,  Currency currency)?  data,TResult Function()?  empty,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading();case DetailData() when data != null:
return data(_that.days,_that.overallSumMinorUnits,_that.currency);case DetailEmpty() when empty != null:
return empty();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<DatedTransactionGroup> days,  int overallSumMinorUnits,  Currency currency)  data,required TResult Function()  empty,}) {final _that = this;
switch (_that) {
case DetailLoading():
return loading();case DetailData():
return data(_that.days,_that.overallSumMinorUnits,_that.currency);case DetailEmpty():
return empty();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<DatedTransactionGroup> days,  int overallSumMinorUnits,  Currency currency)?  data,TResult? Function()?  empty,}) {final _that = this;
switch (_that) {
case DetailLoading() when loading != null:
return loading();case DetailData() when data != null:
return data(_that.days,_that.overallSumMinorUnits,_that.currency);case DetailEmpty() when empty != null:
return empty();case _:
  return null;

}
}

}

/// @nodoc


class DetailLoading implements CategorySearchDetailState {
  const DetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategorySearchDetailState.loading()';
}


}




/// @nodoc


class DetailData implements CategorySearchDetailState {
  const DetailData({required final  List<DatedTransactionGroup> days, required this.overallSumMinorUnits, required this.currency}): _days = days;
  

 final  List<DatedTransactionGroup> _days;
 List<DatedTransactionGroup> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

 final  int overallSumMinorUnits;
 final  Currency currency;

/// Create a copy of CategorySearchDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailDataCopyWith<DetailData> get copyWith => _$DetailDataCopyWithImpl<DetailData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailData&&const DeepCollectionEquality().equals(other._days, _days)&&(identical(other.overallSumMinorUnits, overallSumMinorUnits) || other.overallSumMinorUnits == overallSumMinorUnits)&&(identical(other.currency, currency) || other.currency == currency));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_days),overallSumMinorUnits,currency);

@override
String toString() {
  return 'CategorySearchDetailState.data(days: $days, overallSumMinorUnits: $overallSumMinorUnits, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $DetailDataCopyWith<$Res> implements $CategorySearchDetailStateCopyWith<$Res> {
  factory $DetailDataCopyWith(DetailData value, $Res Function(DetailData) _then) = _$DetailDataCopyWithImpl;
@useResult
$Res call({
 List<DatedTransactionGroup> days, int overallSumMinorUnits, Currency currency
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$DetailDataCopyWithImpl<$Res>
    implements $DetailDataCopyWith<$Res> {
  _$DetailDataCopyWithImpl(this._self, this._then);

  final DetailData _self;
  final $Res Function(DetailData) _then;

/// Create a copy of CategorySearchDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? days = null,Object? overallSumMinorUnits = null,Object? currency = null,}) {
  return _then(DetailData(
days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<DatedTransactionGroup>,overallSumMinorUnits: null == overallSumMinorUnits ? _self.overallSumMinorUnits : overallSumMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,
  ));
}

/// Create a copy of CategorySearchDetailState
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


class DetailEmpty implements CategorySearchDetailState {
  const DetailEmpty();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategorySearchDetailState.empty()';
}


}




/// @nodoc
mixin _$DatedTransactionGroup {

 DateTime get date; List<Transaction> get transactions; int get daySumMinorUnits;
/// Create a copy of DatedTransactionGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatedTransactionGroupCopyWith<DatedTransactionGroup> get copyWith => _$DatedTransactionGroupCopyWithImpl<DatedTransactionGroup>(this as DatedTransactionGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatedTransactionGroup&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.transactions, transactions)&&(identical(other.daySumMinorUnits, daySumMinorUnits) || other.daySumMinorUnits == daySumMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(transactions),daySumMinorUnits);

@override
String toString() {
  return 'DatedTransactionGroup(date: $date, transactions: $transactions, daySumMinorUnits: $daySumMinorUnits)';
}


}

/// @nodoc
abstract mixin class $DatedTransactionGroupCopyWith<$Res>  {
  factory $DatedTransactionGroupCopyWith(DatedTransactionGroup value, $Res Function(DatedTransactionGroup) _then) = _$DatedTransactionGroupCopyWithImpl;
@useResult
$Res call({
 DateTime date, List<Transaction> transactions, int daySumMinorUnits
});




}
/// @nodoc
class _$DatedTransactionGroupCopyWithImpl<$Res>
    implements $DatedTransactionGroupCopyWith<$Res> {
  _$DatedTransactionGroupCopyWithImpl(this._self, this._then);

  final DatedTransactionGroup _self;
  final $Res Function(DatedTransactionGroup) _then;

/// Create a copy of DatedTransactionGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? transactions = null,Object? daySumMinorUnits = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<Transaction>,daySumMinorUnits: null == daySumMinorUnits ? _self.daySumMinorUnits : daySumMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DatedTransactionGroup].
extension DatedTransactionGroupPatterns on DatedTransactionGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatedTransactionGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatedTransactionGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatedTransactionGroup value)  $default,){
final _that = this;
switch (_that) {
case _DatedTransactionGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatedTransactionGroup value)?  $default,){
final _that = this;
switch (_that) {
case _DatedTransactionGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  List<Transaction> transactions,  int daySumMinorUnits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatedTransactionGroup() when $default != null:
return $default(_that.date,_that.transactions,_that.daySumMinorUnits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  List<Transaction> transactions,  int daySumMinorUnits)  $default,) {final _that = this;
switch (_that) {
case _DatedTransactionGroup():
return $default(_that.date,_that.transactions,_that.daySumMinorUnits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  List<Transaction> transactions,  int daySumMinorUnits)?  $default,) {final _that = this;
switch (_that) {
case _DatedTransactionGroup() when $default != null:
return $default(_that.date,_that.transactions,_that.daySumMinorUnits);case _:
  return null;

}
}

}

/// @nodoc


class _DatedTransactionGroup implements DatedTransactionGroup {
  const _DatedTransactionGroup({required this.date, required final  List<Transaction> transactions, required this.daySumMinorUnits}): _transactions = transactions;
  

@override final  DateTime date;
 final  List<Transaction> _transactions;
@override List<Transaction> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}

@override final  int daySumMinorUnits;

/// Create a copy of DatedTransactionGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatedTransactionGroupCopyWith<_DatedTransactionGroup> get copyWith => __$DatedTransactionGroupCopyWithImpl<_DatedTransactionGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatedTransactionGroup&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._transactions, _transactions)&&(identical(other.daySumMinorUnits, daySumMinorUnits) || other.daySumMinorUnits == daySumMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_transactions),daySumMinorUnits);

@override
String toString() {
  return 'DatedTransactionGroup(date: $date, transactions: $transactions, daySumMinorUnits: $daySumMinorUnits)';
}


}

/// @nodoc
abstract mixin class _$DatedTransactionGroupCopyWith<$Res> implements $DatedTransactionGroupCopyWith<$Res> {
  factory _$DatedTransactionGroupCopyWith(_DatedTransactionGroup value, $Res Function(_DatedTransactionGroup) _then) = __$DatedTransactionGroupCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, List<Transaction> transactions, int daySumMinorUnits
});




}
/// @nodoc
class __$DatedTransactionGroupCopyWithImpl<$Res>
    implements _$DatedTransactionGroupCopyWith<$Res> {
  __$DatedTransactionGroupCopyWithImpl(this._self, this._then);

  final _DatedTransactionGroup _self;
  final $Res Function(_DatedTransactionGroup) _then;

/// Create a copy of DatedTransactionGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? transactions = null,Object? daySumMinorUnits = null,}) {
  return _then(_DatedTransactionGroup(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<Transaction>,daySumMinorUnits: null == daySumMinorUnits ? _self.daySumMinorUnits : daySumMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
