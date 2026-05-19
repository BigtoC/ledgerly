// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'charts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChartsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChartsState()';
}


}

/// @nodoc
class $ChartsStateCopyWith<$Res>  {
$ChartsStateCopyWith(ChartsState _, $Res Function(ChartsState) __);
}


/// Adds pattern-matching-related methods to [ChartsState].
extension ChartsStatePatterns on ChartsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChartsIdle value)?  idle,TResult Function( ChartsLoading value)?  loading,TResult Function( ChartsDataState value)?  data,TResult Function( ChartsEmpty value)?  empty,TResult Function( ChartsBlockedByMissingRates value)?  blockedByMissingRates,TResult Function( ChartsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChartsIdle() when idle != null:
return idle(_that);case ChartsLoading() when loading != null:
return loading(_that);case ChartsDataState() when data != null:
return data(_that);case ChartsEmpty() when empty != null:
return empty(_that);case ChartsBlockedByMissingRates() when blockedByMissingRates != null:
return blockedByMissingRates(_that);case ChartsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChartsIdle value)  idle,required TResult Function( ChartsLoading value)  loading,required TResult Function( ChartsDataState value)  data,required TResult Function( ChartsEmpty value)  empty,required TResult Function( ChartsBlockedByMissingRates value)  blockedByMissingRates,required TResult Function( ChartsError value)  error,}){
final _that = this;
switch (_that) {
case ChartsIdle():
return idle(_that);case ChartsLoading():
return loading(_that);case ChartsDataState():
return data(_that);case ChartsEmpty():
return empty(_that);case ChartsBlockedByMissingRates():
return blockedByMissingRates(_that);case ChartsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChartsIdle value)?  idle,TResult? Function( ChartsLoading value)?  loading,TResult? Function( ChartsDataState value)?  data,TResult? Function( ChartsEmpty value)?  empty,TResult? Function( ChartsBlockedByMissingRates value)?  blockedByMissingRates,TResult? Function( ChartsError value)?  error,}){
final _that = this;
switch (_that) {
case ChartsIdle() when idle != null:
return idle(_that);case ChartsLoading() when loading != null:
return loading(_that);case ChartsDataState() when data != null:
return data(_that);case ChartsEmpty() when empty != null:
return empty(_that);case ChartsBlockedByMissingRates() when blockedByMissingRates != null:
return blockedByMissingRates(_that);case ChartsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( ChartsData? previous)?  loading,TResult Function( ChartsData chartData)?  data,TResult Function()?  empty,TResult Function( ChartsData? previous)?  blockedByMissingRates,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChartsIdle() when idle != null:
return idle();case ChartsLoading() when loading != null:
return loading(_that.previous);case ChartsDataState() when data != null:
return data(_that.chartData);case ChartsEmpty() when empty != null:
return empty();case ChartsBlockedByMissingRates() when blockedByMissingRates != null:
return blockedByMissingRates(_that.previous);case ChartsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( ChartsData? previous)  loading,required TResult Function( ChartsData chartData)  data,required TResult Function()  empty,required TResult Function( ChartsData? previous)  blockedByMissingRates,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case ChartsIdle():
return idle();case ChartsLoading():
return loading(_that.previous);case ChartsDataState():
return data(_that.chartData);case ChartsEmpty():
return empty();case ChartsBlockedByMissingRates():
return blockedByMissingRates(_that.previous);case ChartsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( ChartsData? previous)?  loading,TResult? Function( ChartsData chartData)?  data,TResult? Function()?  empty,TResult? Function( ChartsData? previous)?  blockedByMissingRates,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case ChartsIdle() when idle != null:
return idle();case ChartsLoading() when loading != null:
return loading(_that.previous);case ChartsDataState() when data != null:
return data(_that.chartData);case ChartsEmpty() when empty != null:
return empty();case ChartsBlockedByMissingRates() when blockedByMissingRates != null:
return blockedByMissingRates(_that.previous);case ChartsError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class ChartsIdle implements ChartsState {
  const ChartsIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChartsState.idle()';
}


}




/// @nodoc


class ChartsLoading implements ChartsState {
  const ChartsLoading({this.previous});
  

 final  ChartsData? previous;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartsLoadingCopyWith<ChartsLoading> get copyWith => _$ChartsLoadingCopyWithImpl<ChartsLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsLoading&&(identical(other.previous, previous) || other.previous == previous));
}


@override
int get hashCode => Object.hash(runtimeType,previous);

@override
String toString() {
  return 'ChartsState.loading(previous: $previous)';
}


}

/// @nodoc
abstract mixin class $ChartsLoadingCopyWith<$Res> implements $ChartsStateCopyWith<$Res> {
  factory $ChartsLoadingCopyWith(ChartsLoading value, $Res Function(ChartsLoading) _then) = _$ChartsLoadingCopyWithImpl;
@useResult
$Res call({
 ChartsData? previous
});


$ChartsDataCopyWith<$Res>? get previous;

}
/// @nodoc
class _$ChartsLoadingCopyWithImpl<$Res>
    implements $ChartsLoadingCopyWith<$Res> {
  _$ChartsLoadingCopyWithImpl(this._self, this._then);

  final ChartsLoading _self;
  final $Res Function(ChartsLoading) _then;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? previous = freezed,}) {
  return _then(ChartsLoading(
previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as ChartsData?,
  ));
}

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartsDataCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $ChartsDataCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}
}

/// @nodoc


class ChartsDataState implements ChartsState {
  const ChartsDataState({required this.chartData});
  

 final  ChartsData chartData;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartsDataStateCopyWith<ChartsDataState> get copyWith => _$ChartsDataStateCopyWithImpl<ChartsDataState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsDataState&&(identical(other.chartData, chartData) || other.chartData == chartData));
}


@override
int get hashCode => Object.hash(runtimeType,chartData);

@override
String toString() {
  return 'ChartsState.data(chartData: $chartData)';
}


}

/// @nodoc
abstract mixin class $ChartsDataStateCopyWith<$Res> implements $ChartsStateCopyWith<$Res> {
  factory $ChartsDataStateCopyWith(ChartsDataState value, $Res Function(ChartsDataState) _then) = _$ChartsDataStateCopyWithImpl;
@useResult
$Res call({
 ChartsData chartData
});


$ChartsDataCopyWith<$Res> get chartData;

}
/// @nodoc
class _$ChartsDataStateCopyWithImpl<$Res>
    implements $ChartsDataStateCopyWith<$Res> {
  _$ChartsDataStateCopyWithImpl(this._self, this._then);

  final ChartsDataState _self;
  final $Res Function(ChartsDataState) _then;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? chartData = null,}) {
  return _then(ChartsDataState(
chartData: null == chartData ? _self.chartData : chartData // ignore: cast_nullable_to_non_nullable
as ChartsData,
  ));
}

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartsDataCopyWith<$Res> get chartData {
  
  return $ChartsDataCopyWith<$Res>(_self.chartData, (value) {
    return _then(_self.copyWith(chartData: value));
  });
}
}

/// @nodoc


class ChartsEmpty implements ChartsState {
  const ChartsEmpty();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChartsState.empty()';
}


}




/// @nodoc


class ChartsBlockedByMissingRates implements ChartsState {
  const ChartsBlockedByMissingRates({this.previous});
  

 final  ChartsData? previous;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartsBlockedByMissingRatesCopyWith<ChartsBlockedByMissingRates> get copyWith => _$ChartsBlockedByMissingRatesCopyWithImpl<ChartsBlockedByMissingRates>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsBlockedByMissingRates&&(identical(other.previous, previous) || other.previous == previous));
}


@override
int get hashCode => Object.hash(runtimeType,previous);

@override
String toString() {
  return 'ChartsState.blockedByMissingRates(previous: $previous)';
}


}

/// @nodoc
abstract mixin class $ChartsBlockedByMissingRatesCopyWith<$Res> implements $ChartsStateCopyWith<$Res> {
  factory $ChartsBlockedByMissingRatesCopyWith(ChartsBlockedByMissingRates value, $Res Function(ChartsBlockedByMissingRates) _then) = _$ChartsBlockedByMissingRatesCopyWithImpl;
@useResult
$Res call({
 ChartsData? previous
});


$ChartsDataCopyWith<$Res>? get previous;

}
/// @nodoc
class _$ChartsBlockedByMissingRatesCopyWithImpl<$Res>
    implements $ChartsBlockedByMissingRatesCopyWith<$Res> {
  _$ChartsBlockedByMissingRatesCopyWithImpl(this._self, this._then);

  final ChartsBlockedByMissingRates _self;
  final $Res Function(ChartsBlockedByMissingRates) _then;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? previous = freezed,}) {
  return _then(ChartsBlockedByMissingRates(
previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as ChartsData?,
  ));
}

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartsDataCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $ChartsDataCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}
}

/// @nodoc


class ChartsError implements ChartsState {
  const ChartsError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartsErrorCopyWith<ChartsError> get copyWith => _$ChartsErrorCopyWithImpl<ChartsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'ChartsState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $ChartsErrorCopyWith<$Res> implements $ChartsStateCopyWith<$Res> {
  factory $ChartsErrorCopyWith(ChartsError value, $Res Function(ChartsError) _then) = _$ChartsErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$ChartsErrorCopyWithImpl<$Res>
    implements $ChartsErrorCopyWith<$Res> {
  _$ChartsErrorCopyWithImpl(this._self, this._then);

  final ChartsError _self;
  final $Res Function(ChartsError) _then;

/// Create a copy of ChartsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(ChartsError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

/// @nodoc
mixin _$ChartsData {

 PeriodType get period; DateTime get anchorDate; CategoryType get type; ChartDimension get dimension; List<ChartSlice> get slices; List<ChartBucketTotal> get bucketTotals;/// Only set when every active subtotal is comparable in one
/// display currency. Null in currency-view-with-mixed-rates.
 int? get grandTotalMinorUnits;/// Set when slices are unified into one display currency. Null when
/// each slice keeps its own `currencyCode` (currency dimension with
/// missing rates).
 String? get displayCurrencyCode; bool get mixedCurrencies;/// True when Task 12's cold-start fallback auto-switched the active
/// dimension from `category` to `currency` because category view was
/// blocked by missing FX rates. `ChartsSection` reads this flag to
/// render an explanatory banner above the chart body. Cleared when
/// the user manually changes dimension or dismisses the banner.
 bool get autoSwitchedFromCategoryDimension;/// Currency codes whose subtotals were dropped from this chart
/// because their FX rate was missing at emit time. Empty in the
/// all-rates-present case. When non-empty, `ChartsSection` renders
/// a ribbon listing them above the chart body. Category/account
/// dimension only — currency dimension shows source amounts inline.
 List<String> get excludedCurrencyCodes;
/// Create a copy of ChartsData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartsDataCopyWith<ChartsData> get copyWith => _$ChartsDataCopyWithImpl<ChartsData>(this as ChartsData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsData&&(identical(other.period, period) || other.period == period)&&(identical(other.anchorDate, anchorDate) || other.anchorDate == anchorDate)&&(identical(other.type, type) || other.type == type)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&const DeepCollectionEquality().equals(other.slices, slices)&&const DeepCollectionEquality().equals(other.bucketTotals, bucketTotals)&&(identical(other.grandTotalMinorUnits, grandTotalMinorUnits) || other.grandTotalMinorUnits == grandTotalMinorUnits)&&(identical(other.displayCurrencyCode, displayCurrencyCode) || other.displayCurrencyCode == displayCurrencyCode)&&(identical(other.mixedCurrencies, mixedCurrencies) || other.mixedCurrencies == mixedCurrencies)&&(identical(other.autoSwitchedFromCategoryDimension, autoSwitchedFromCategoryDimension) || other.autoSwitchedFromCategoryDimension == autoSwitchedFromCategoryDimension)&&const DeepCollectionEquality().equals(other.excludedCurrencyCodes, excludedCurrencyCodes));
}


@override
int get hashCode => Object.hash(runtimeType,period,anchorDate,type,dimension,const DeepCollectionEquality().hash(slices),const DeepCollectionEquality().hash(bucketTotals),grandTotalMinorUnits,displayCurrencyCode,mixedCurrencies,autoSwitchedFromCategoryDimension,const DeepCollectionEquality().hash(excludedCurrencyCodes));

@override
String toString() {
  return 'ChartsData(period: $period, anchorDate: $anchorDate, type: $type, dimension: $dimension, slices: $slices, bucketTotals: $bucketTotals, grandTotalMinorUnits: $grandTotalMinorUnits, displayCurrencyCode: $displayCurrencyCode, mixedCurrencies: $mixedCurrencies, autoSwitchedFromCategoryDimension: $autoSwitchedFromCategoryDimension, excludedCurrencyCodes: $excludedCurrencyCodes)';
}


}

/// @nodoc
abstract mixin class $ChartsDataCopyWith<$Res>  {
  factory $ChartsDataCopyWith(ChartsData value, $Res Function(ChartsData) _then) = _$ChartsDataCopyWithImpl;
@useResult
$Res call({
 PeriodType period, DateTime anchorDate, CategoryType type, ChartDimension dimension, List<ChartSlice> slices, List<ChartBucketTotal> bucketTotals, int? grandTotalMinorUnits, String? displayCurrencyCode, bool mixedCurrencies, bool autoSwitchedFromCategoryDimension, List<String> excludedCurrencyCodes
});




}
/// @nodoc
class _$ChartsDataCopyWithImpl<$Res>
    implements $ChartsDataCopyWith<$Res> {
  _$ChartsDataCopyWithImpl(this._self, this._then);

  final ChartsData _self;
  final $Res Function(ChartsData) _then;

/// Create a copy of ChartsData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? anchorDate = null,Object? type = null,Object? dimension = null,Object? slices = null,Object? bucketTotals = null,Object? grandTotalMinorUnits = freezed,Object? displayCurrencyCode = freezed,Object? mixedCurrencies = null,Object? autoSwitchedFromCategoryDimension = null,Object? excludedCurrencyCodes = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodType,anchorDate: null == anchorDate ? _self.anchorDate : anchorDate // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as ChartDimension,slices: null == slices ? _self.slices : slices // ignore: cast_nullable_to_non_nullable
as List<ChartSlice>,bucketTotals: null == bucketTotals ? _self.bucketTotals : bucketTotals // ignore: cast_nullable_to_non_nullable
as List<ChartBucketTotal>,grandTotalMinorUnits: freezed == grandTotalMinorUnits ? _self.grandTotalMinorUnits : grandTotalMinorUnits // ignore: cast_nullable_to_non_nullable
as int?,displayCurrencyCode: freezed == displayCurrencyCode ? _self.displayCurrencyCode : displayCurrencyCode // ignore: cast_nullable_to_non_nullable
as String?,mixedCurrencies: null == mixedCurrencies ? _self.mixedCurrencies : mixedCurrencies // ignore: cast_nullable_to_non_nullable
as bool,autoSwitchedFromCategoryDimension: null == autoSwitchedFromCategoryDimension ? _self.autoSwitchedFromCategoryDimension : autoSwitchedFromCategoryDimension // ignore: cast_nullable_to_non_nullable
as bool,excludedCurrencyCodes: null == excludedCurrencyCodes ? _self.excludedCurrencyCodes : excludedCurrencyCodes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartsData].
extension ChartsDataPatterns on ChartsData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartsData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartsData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartsData value)  $default,){
final _that = this;
switch (_that) {
case _ChartsData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartsData value)?  $default,){
final _that = this;
switch (_that) {
case _ChartsData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PeriodType period,  DateTime anchorDate,  CategoryType type,  ChartDimension dimension,  List<ChartSlice> slices,  List<ChartBucketTotal> bucketTotals,  int? grandTotalMinorUnits,  String? displayCurrencyCode,  bool mixedCurrencies,  bool autoSwitchedFromCategoryDimension,  List<String> excludedCurrencyCodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartsData() when $default != null:
return $default(_that.period,_that.anchorDate,_that.type,_that.dimension,_that.slices,_that.bucketTotals,_that.grandTotalMinorUnits,_that.displayCurrencyCode,_that.mixedCurrencies,_that.autoSwitchedFromCategoryDimension,_that.excludedCurrencyCodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PeriodType period,  DateTime anchorDate,  CategoryType type,  ChartDimension dimension,  List<ChartSlice> slices,  List<ChartBucketTotal> bucketTotals,  int? grandTotalMinorUnits,  String? displayCurrencyCode,  bool mixedCurrencies,  bool autoSwitchedFromCategoryDimension,  List<String> excludedCurrencyCodes)  $default,) {final _that = this;
switch (_that) {
case _ChartsData():
return $default(_that.period,_that.anchorDate,_that.type,_that.dimension,_that.slices,_that.bucketTotals,_that.grandTotalMinorUnits,_that.displayCurrencyCode,_that.mixedCurrencies,_that.autoSwitchedFromCategoryDimension,_that.excludedCurrencyCodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PeriodType period,  DateTime anchorDate,  CategoryType type,  ChartDimension dimension,  List<ChartSlice> slices,  List<ChartBucketTotal> bucketTotals,  int? grandTotalMinorUnits,  String? displayCurrencyCode,  bool mixedCurrencies,  bool autoSwitchedFromCategoryDimension,  List<String> excludedCurrencyCodes)?  $default,) {final _that = this;
switch (_that) {
case _ChartsData() when $default != null:
return $default(_that.period,_that.anchorDate,_that.type,_that.dimension,_that.slices,_that.bucketTotals,_that.grandTotalMinorUnits,_that.displayCurrencyCode,_that.mixedCurrencies,_that.autoSwitchedFromCategoryDimension,_that.excludedCurrencyCodes);case _:
  return null;

}
}

}

/// @nodoc


class _ChartsData implements ChartsData {
  const _ChartsData({required this.period, required this.anchorDate, required this.type, required this.dimension, required final  List<ChartSlice> slices, required final  List<ChartBucketTotal> bucketTotals, required this.grandTotalMinorUnits, required this.displayCurrencyCode, this.mixedCurrencies = false, this.autoSwitchedFromCategoryDimension = false, final  List<String> excludedCurrencyCodes = const <String>[]}): _slices = slices,_bucketTotals = bucketTotals,_excludedCurrencyCodes = excludedCurrencyCodes;
  

@override final  PeriodType period;
@override final  DateTime anchorDate;
@override final  CategoryType type;
@override final  ChartDimension dimension;
 final  List<ChartSlice> _slices;
@override List<ChartSlice> get slices {
  if (_slices is EqualUnmodifiableListView) return _slices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slices);
}

 final  List<ChartBucketTotal> _bucketTotals;
@override List<ChartBucketTotal> get bucketTotals {
  if (_bucketTotals is EqualUnmodifiableListView) return _bucketTotals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bucketTotals);
}

/// Only set when every active subtotal is comparable in one
/// display currency. Null in currency-view-with-mixed-rates.
@override final  int? grandTotalMinorUnits;
/// Set when slices are unified into one display currency. Null when
/// each slice keeps its own `currencyCode` (currency dimension with
/// missing rates).
@override final  String? displayCurrencyCode;
@override@JsonKey() final  bool mixedCurrencies;
/// True when Task 12's cold-start fallback auto-switched the active
/// dimension from `category` to `currency` because category view was
/// blocked by missing FX rates. `ChartsSection` reads this flag to
/// render an explanatory banner above the chart body. Cleared when
/// the user manually changes dimension or dismisses the banner.
@override@JsonKey() final  bool autoSwitchedFromCategoryDimension;
/// Currency codes whose subtotals were dropped from this chart
/// because their FX rate was missing at emit time. Empty in the
/// all-rates-present case. When non-empty, `ChartsSection` renders
/// a ribbon listing them above the chart body. Category/account
/// dimension only — currency dimension shows source amounts inline.
 final  List<String> _excludedCurrencyCodes;
/// Currency codes whose subtotals were dropped from this chart
/// because their FX rate was missing at emit time. Empty in the
/// all-rates-present case. When non-empty, `ChartsSection` renders
/// a ribbon listing them above the chart body. Category/account
/// dimension only — currency dimension shows source amounts inline.
@override@JsonKey() List<String> get excludedCurrencyCodes {
  if (_excludedCurrencyCodes is EqualUnmodifiableListView) return _excludedCurrencyCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_excludedCurrencyCodes);
}


/// Create a copy of ChartsData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartsDataCopyWith<_ChartsData> get copyWith => __$ChartsDataCopyWithImpl<_ChartsData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartsData&&(identical(other.period, period) || other.period == period)&&(identical(other.anchorDate, anchorDate) || other.anchorDate == anchorDate)&&(identical(other.type, type) || other.type == type)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&const DeepCollectionEquality().equals(other._slices, _slices)&&const DeepCollectionEquality().equals(other._bucketTotals, _bucketTotals)&&(identical(other.grandTotalMinorUnits, grandTotalMinorUnits) || other.grandTotalMinorUnits == grandTotalMinorUnits)&&(identical(other.displayCurrencyCode, displayCurrencyCode) || other.displayCurrencyCode == displayCurrencyCode)&&(identical(other.mixedCurrencies, mixedCurrencies) || other.mixedCurrencies == mixedCurrencies)&&(identical(other.autoSwitchedFromCategoryDimension, autoSwitchedFromCategoryDimension) || other.autoSwitchedFromCategoryDimension == autoSwitchedFromCategoryDimension)&&const DeepCollectionEquality().equals(other._excludedCurrencyCodes, _excludedCurrencyCodes));
}


@override
int get hashCode => Object.hash(runtimeType,period,anchorDate,type,dimension,const DeepCollectionEquality().hash(_slices),const DeepCollectionEquality().hash(_bucketTotals),grandTotalMinorUnits,displayCurrencyCode,mixedCurrencies,autoSwitchedFromCategoryDimension,const DeepCollectionEquality().hash(_excludedCurrencyCodes));

@override
String toString() {
  return 'ChartsData(period: $period, anchorDate: $anchorDate, type: $type, dimension: $dimension, slices: $slices, bucketTotals: $bucketTotals, grandTotalMinorUnits: $grandTotalMinorUnits, displayCurrencyCode: $displayCurrencyCode, mixedCurrencies: $mixedCurrencies, autoSwitchedFromCategoryDimension: $autoSwitchedFromCategoryDimension, excludedCurrencyCodes: $excludedCurrencyCodes)';
}


}

/// @nodoc
abstract mixin class _$ChartsDataCopyWith<$Res> implements $ChartsDataCopyWith<$Res> {
  factory _$ChartsDataCopyWith(_ChartsData value, $Res Function(_ChartsData) _then) = __$ChartsDataCopyWithImpl;
@override @useResult
$Res call({
 PeriodType period, DateTime anchorDate, CategoryType type, ChartDimension dimension, List<ChartSlice> slices, List<ChartBucketTotal> bucketTotals, int? grandTotalMinorUnits, String? displayCurrencyCode, bool mixedCurrencies, bool autoSwitchedFromCategoryDimension, List<String> excludedCurrencyCodes
});




}
/// @nodoc
class __$ChartsDataCopyWithImpl<$Res>
    implements _$ChartsDataCopyWith<$Res> {
  __$ChartsDataCopyWithImpl(this._self, this._then);

  final _ChartsData _self;
  final $Res Function(_ChartsData) _then;

/// Create a copy of ChartsData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? anchorDate = null,Object? type = null,Object? dimension = null,Object? slices = null,Object? bucketTotals = null,Object? grandTotalMinorUnits = freezed,Object? displayCurrencyCode = freezed,Object? mixedCurrencies = null,Object? autoSwitchedFromCategoryDimension = null,Object? excludedCurrencyCodes = null,}) {
  return _then(_ChartsData(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodType,anchorDate: null == anchorDate ? _self.anchorDate : anchorDate // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as ChartDimension,slices: null == slices ? _self._slices : slices // ignore: cast_nullable_to_non_nullable
as List<ChartSlice>,bucketTotals: null == bucketTotals ? _self._bucketTotals : bucketTotals // ignore: cast_nullable_to_non_nullable
as List<ChartBucketTotal>,grandTotalMinorUnits: freezed == grandTotalMinorUnits ? _self.grandTotalMinorUnits : grandTotalMinorUnits // ignore: cast_nullable_to_non_nullable
as int?,displayCurrencyCode: freezed == displayCurrencyCode ? _self.displayCurrencyCode : displayCurrencyCode // ignore: cast_nullable_to_non_nullable
as String?,mixedCurrencies: null == mixedCurrencies ? _self.mixedCurrencies : mixedCurrencies // ignore: cast_nullable_to_non_nullable
as bool,autoSwitchedFromCategoryDimension: null == autoSwitchedFromCategoryDimension ? _self.autoSwitchedFromCategoryDimension : autoSwitchedFromCategoryDimension // ignore: cast_nullable_to_non_nullable
as bool,excludedCurrencyCodes: null == excludedCurrencyCodes ? _self._excludedCurrencyCodes : excludedCurrencyCodes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$ChartSlice {

/// Resolved display label (category name, account name, or currency
/// code). The controller resolves labels so widgets stay pure.
 String get label;/// Currency to format `totalMinorUnits` in. Equals
/// `ChartsData.displayCurrencyCode` for converted slices; equals the
/// source currency for currency-view-mixed slices.
 String get currencyCode; int get totalMinorUnits;/// `0.0–1.0` when `ChartsData.grandTotalMinorUnits != null`,
/// otherwise null (hide percentage label).
 double? get fraction;/// Index into `core/utils/color_palette.dart`.
 int get colorIndex;/// `core/utils/icon_registry.dart` key for legend icon. Empty string
/// for currency-dimension slices.
 String get iconKey;
/// Create a copy of ChartSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartSliceCopyWith<ChartSlice> get copyWith => _$ChartSliceCopyWithImpl<ChartSlice>(this as ChartSlice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartSlice&&(identical(other.label, label) || other.label == label)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.colorIndex, colorIndex) || other.colorIndex == colorIndex)&&(identical(other.iconKey, iconKey) || other.iconKey == iconKey));
}


@override
int get hashCode => Object.hash(runtimeType,label,currencyCode,totalMinorUnits,fraction,colorIndex,iconKey);

@override
String toString() {
  return 'ChartSlice(label: $label, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits, fraction: $fraction, colorIndex: $colorIndex, iconKey: $iconKey)';
}


}

/// @nodoc
abstract mixin class $ChartSliceCopyWith<$Res>  {
  factory $ChartSliceCopyWith(ChartSlice value, $Res Function(ChartSlice) _then) = _$ChartSliceCopyWithImpl;
@useResult
$Res call({
 String label, String currencyCode, int totalMinorUnits, double? fraction, int colorIndex, String iconKey
});




}
/// @nodoc
class _$ChartSliceCopyWithImpl<$Res>
    implements $ChartSliceCopyWith<$Res> {
  _$ChartSliceCopyWithImpl(this._self, this._then);

  final ChartSlice _self;
  final $Res Function(ChartSlice) _then;

/// Create a copy of ChartSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? currencyCode = null,Object? totalMinorUnits = null,Object? fraction = freezed,Object? colorIndex = null,Object? iconKey = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,colorIndex: null == colorIndex ? _self.colorIndex : colorIndex // ignore: cast_nullable_to_non_nullable
as int,iconKey: null == iconKey ? _self.iconKey : iconKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartSlice].
extension ChartSlicePatterns on ChartSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartSlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartSlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartSlice value)  $default,){
final _that = this;
switch (_that) {
case _ChartSlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartSlice value)?  $default,){
final _that = this;
switch (_that) {
case _ChartSlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String currencyCode,  int totalMinorUnits,  double? fraction,  int colorIndex,  String iconKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartSlice() when $default != null:
return $default(_that.label,_that.currencyCode,_that.totalMinorUnits,_that.fraction,_that.colorIndex,_that.iconKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String currencyCode,  int totalMinorUnits,  double? fraction,  int colorIndex,  String iconKey)  $default,) {final _that = this;
switch (_that) {
case _ChartSlice():
return $default(_that.label,_that.currencyCode,_that.totalMinorUnits,_that.fraction,_that.colorIndex,_that.iconKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String currencyCode,  int totalMinorUnits,  double? fraction,  int colorIndex,  String iconKey)?  $default,) {final _that = this;
switch (_that) {
case _ChartSlice() when $default != null:
return $default(_that.label,_that.currencyCode,_that.totalMinorUnits,_that.fraction,_that.colorIndex,_that.iconKey);case _:
  return null;

}
}

}

/// @nodoc


class _ChartSlice implements ChartSlice {
  const _ChartSlice({required this.label, required this.currencyCode, required this.totalMinorUnits, this.fraction, required this.colorIndex, required this.iconKey});
  

/// Resolved display label (category name, account name, or currency
/// code). The controller resolves labels so widgets stay pure.
@override final  String label;
/// Currency to format `totalMinorUnits` in. Equals
/// `ChartsData.displayCurrencyCode` for converted slices; equals the
/// source currency for currency-view-mixed slices.
@override final  String currencyCode;
@override final  int totalMinorUnits;
/// `0.0–1.0` when `ChartsData.grandTotalMinorUnits != null`,
/// otherwise null (hide percentage label).
@override final  double? fraction;
/// Index into `core/utils/color_palette.dart`.
@override final  int colorIndex;
/// `core/utils/icon_registry.dart` key for legend icon. Empty string
/// for currency-dimension slices.
@override final  String iconKey;

/// Create a copy of ChartSlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartSliceCopyWith<_ChartSlice> get copyWith => __$ChartSliceCopyWithImpl<_ChartSlice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartSlice&&(identical(other.label, label) || other.label == label)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.colorIndex, colorIndex) || other.colorIndex == colorIndex)&&(identical(other.iconKey, iconKey) || other.iconKey == iconKey));
}


@override
int get hashCode => Object.hash(runtimeType,label,currencyCode,totalMinorUnits,fraction,colorIndex,iconKey);

@override
String toString() {
  return 'ChartSlice(label: $label, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits, fraction: $fraction, colorIndex: $colorIndex, iconKey: $iconKey)';
}


}

/// @nodoc
abstract mixin class _$ChartSliceCopyWith<$Res> implements $ChartSliceCopyWith<$Res> {
  factory _$ChartSliceCopyWith(_ChartSlice value, $Res Function(_ChartSlice) _then) = __$ChartSliceCopyWithImpl;
@override @useResult
$Res call({
 String label, String currencyCode, int totalMinorUnits, double? fraction, int colorIndex, String iconKey
});




}
/// @nodoc
class __$ChartSliceCopyWithImpl<$Res>
    implements _$ChartSliceCopyWith<$Res> {
  __$ChartSliceCopyWithImpl(this._self, this._then);

  final _ChartSlice _self;
  final $Res Function(_ChartSlice) _then;

/// Create a copy of ChartSlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? currencyCode = null,Object? totalMinorUnits = null,Object? fraction = freezed,Object? colorIndex = null,Object? iconKey = null,}) {
  return _then(_ChartSlice(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,colorIndex: null == colorIndex ? _self.colorIndex : colorIndex // ignore: cast_nullable_to_non_nullable
as int,iconKey: null == iconKey ? _self.iconKey : iconKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ChartBucketTotal {

 DateTime get bucketStart; int get totalMinorUnits;
/// Create a copy of ChartBucketTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartBucketTotalCopyWith<ChartBucketTotal> get copyWith => _$ChartBucketTotalCopyWithImpl<ChartBucketTotal>(this as ChartBucketTotal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartBucketTotal&&(identical(other.bucketStart, bucketStart) || other.bucketStart == bucketStart)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,bucketStart,totalMinorUnits);

@override
String toString() {
  return 'ChartBucketTotal(bucketStart: $bucketStart, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class $ChartBucketTotalCopyWith<$Res>  {
  factory $ChartBucketTotalCopyWith(ChartBucketTotal value, $Res Function(ChartBucketTotal) _then) = _$ChartBucketTotalCopyWithImpl;
@useResult
$Res call({
 DateTime bucketStart, int totalMinorUnits
});




}
/// @nodoc
class _$ChartBucketTotalCopyWithImpl<$Res>
    implements $ChartBucketTotalCopyWith<$Res> {
  _$ChartBucketTotalCopyWithImpl(this._self, this._then);

  final ChartBucketTotal _self;
  final $Res Function(ChartBucketTotal) _then;

/// Create a copy of ChartBucketTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bucketStart = null,Object? totalMinorUnits = null,}) {
  return _then(_self.copyWith(
bucketStart: null == bucketStart ? _self.bucketStart : bucketStart // ignore: cast_nullable_to_non_nullable
as DateTime,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartBucketTotal].
extension ChartBucketTotalPatterns on ChartBucketTotal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartBucketTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartBucketTotal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartBucketTotal value)  $default,){
final _that = this;
switch (_that) {
case _ChartBucketTotal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartBucketTotal value)?  $default,){
final _that = this;
switch (_that) {
case _ChartBucketTotal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime bucketStart,  int totalMinorUnits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartBucketTotal() when $default != null:
return $default(_that.bucketStart,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime bucketStart,  int totalMinorUnits)  $default,) {final _that = this;
switch (_that) {
case _ChartBucketTotal():
return $default(_that.bucketStart,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime bucketStart,  int totalMinorUnits)?  $default,) {final _that = this;
switch (_that) {
case _ChartBucketTotal() when $default != null:
return $default(_that.bucketStart,_that.totalMinorUnits);case _:
  return null;

}
}

}

/// @nodoc


class _ChartBucketTotal implements ChartBucketTotal {
  const _ChartBucketTotal({required this.bucketStart, required this.totalMinorUnits});
  

@override final  DateTime bucketStart;
@override final  int totalMinorUnits;

/// Create a copy of ChartBucketTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartBucketTotalCopyWith<_ChartBucketTotal> get copyWith => __$ChartBucketTotalCopyWithImpl<_ChartBucketTotal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartBucketTotal&&(identical(other.bucketStart, bucketStart) || other.bucketStart == bucketStart)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,bucketStart,totalMinorUnits);

@override
String toString() {
  return 'ChartBucketTotal(bucketStart: $bucketStart, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class _$ChartBucketTotalCopyWith<$Res> implements $ChartBucketTotalCopyWith<$Res> {
  factory _$ChartBucketTotalCopyWith(_ChartBucketTotal value, $Res Function(_ChartBucketTotal) _then) = __$ChartBucketTotalCopyWithImpl;
@override @useResult
$Res call({
 DateTime bucketStart, int totalMinorUnits
});




}
/// @nodoc
class __$ChartBucketTotalCopyWithImpl<$Res>
    implements _$ChartBucketTotalCopyWith<$Res> {
  __$ChartBucketTotalCopyWithImpl(this._self, this._then);

  final _ChartBucketTotal _self;
  final $Res Function(_ChartBucketTotal) _then;

/// Create a copy of ChartBucketTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bucketStart = null,Object? totalMinorUnits = null,}) {
  return _then(_ChartBucketTotal(
bucketStart: null == bucketStart ? _self.bucketStart : bucketStart // ignore: cast_nullable_to_non_nullable
as DateTime,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
