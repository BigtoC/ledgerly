// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AnalysisState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AnalysisState()';
}


}

/// @nodoc
class $AnalysisStateCopyWith<$Res>  {
$AnalysisStateCopyWith(AnalysisState _, $Res Function(AnalysisState) __);
}


/// Adds pattern-matching-related methods to [AnalysisState].
extension AnalysisStatePatterns on AnalysisState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AnalysisIdle value)?  idle,TResult Function( AnalysisLoading value)?  loading,TResult Function( AnalysisResults value)?  results,TResult Function( AnalysisEmpty value)?  empty,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AnalysisIdle() when idle != null:
return idle(_that);case AnalysisLoading() when loading != null:
return loading(_that);case AnalysisResults() when results != null:
return results(_that);case AnalysisEmpty() when empty != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AnalysisIdle value)  idle,required TResult Function( AnalysisLoading value)  loading,required TResult Function( AnalysisResults value)  results,required TResult Function( AnalysisEmpty value)  empty,}){
final _that = this;
switch (_that) {
case AnalysisIdle():
return idle(_that);case AnalysisLoading():
return loading(_that);case AnalysisResults():
return results(_that);case AnalysisEmpty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AnalysisIdle value)?  idle,TResult? Function( AnalysisLoading value)?  loading,TResult? Function( AnalysisResults value)?  results,TResult? Function( AnalysisEmpty value)?  empty,}){
final _that = this;
switch (_that) {
case AnalysisIdle() when idle != null:
return idle(_that);case AnalysisLoading() when loading != null:
return loading(_that);case AnalysisResults() when results != null:
return results(_that);case AnalysisEmpty() when empty != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( String query,  List<CategorySearchResult>? previous)?  loading,TResult Function( List<CategorySearchResult> categories,  String query)?  results,TResult Function( String query)?  empty,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AnalysisIdle() when idle != null:
return idle();case AnalysisLoading() when loading != null:
return loading(_that.query,_that.previous);case AnalysisResults() when results != null:
return results(_that.categories,_that.query);case AnalysisEmpty() when empty != null:
return empty(_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( String query,  List<CategorySearchResult>? previous)  loading,required TResult Function( List<CategorySearchResult> categories,  String query)  results,required TResult Function( String query)  empty,}) {final _that = this;
switch (_that) {
case AnalysisIdle():
return idle();case AnalysisLoading():
return loading(_that.query,_that.previous);case AnalysisResults():
return results(_that.categories,_that.query);case AnalysisEmpty():
return empty(_that.query);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( String query,  List<CategorySearchResult>? previous)?  loading,TResult? Function( List<CategorySearchResult> categories,  String query)?  results,TResult? Function( String query)?  empty,}) {final _that = this;
switch (_that) {
case AnalysisIdle() when idle != null:
return idle();case AnalysisLoading() when loading != null:
return loading(_that.query,_that.previous);case AnalysisResults() when results != null:
return results(_that.categories,_that.query);case AnalysisEmpty() when empty != null:
return empty(_that.query);case _:
  return null;

}
}

}

/// @nodoc


class AnalysisIdle implements AnalysisState {
  const AnalysisIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AnalysisState.idle()';
}


}




/// @nodoc


class AnalysisLoading implements AnalysisState {
  const AnalysisLoading({required this.query, final  List<CategorySearchResult>? previous}): _previous = previous;
  

 final  String query;
 final  List<CategorySearchResult>? _previous;
 List<CategorySearchResult>? get previous {
  final value = _previous;
  if (value == null) return null;
  if (_previous is EqualUnmodifiableListView) return _previous;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisLoadingCopyWith<AnalysisLoading> get copyWith => _$AnalysisLoadingCopyWithImpl<AnalysisLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisLoading&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._previous, _previous));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_previous));

@override
String toString() {
  return 'AnalysisState.loading(query: $query, previous: $previous)';
}


}

/// @nodoc
abstract mixin class $AnalysisLoadingCopyWith<$Res> implements $AnalysisStateCopyWith<$Res> {
  factory $AnalysisLoadingCopyWith(AnalysisLoading value, $Res Function(AnalysisLoading) _then) = _$AnalysisLoadingCopyWithImpl;
@useResult
$Res call({
 String query, List<CategorySearchResult>? previous
});




}
/// @nodoc
class _$AnalysisLoadingCopyWithImpl<$Res>
    implements $AnalysisLoadingCopyWith<$Res> {
  _$AnalysisLoadingCopyWithImpl(this._self, this._then);

  final AnalysisLoading _self;
  final $Res Function(AnalysisLoading) _then;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,Object? previous = freezed,}) {
  return _then(AnalysisLoading(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,previous: freezed == previous ? _self._previous : previous // ignore: cast_nullable_to_non_nullable
as List<CategorySearchResult>?,
  ));
}


}

/// @nodoc


class AnalysisResults implements AnalysisState {
  const AnalysisResults({required final  List<CategorySearchResult> categories, required this.query}): _categories = categories;
  

 final  List<CategorySearchResult> _categories;
 List<CategorySearchResult> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  String query;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisResultsCopyWith<AnalysisResults> get copyWith => _$AnalysisResultsCopyWithImpl<AnalysisResults>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisResults&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),query);

@override
String toString() {
  return 'AnalysisState.results(categories: $categories, query: $query)';
}


}

/// @nodoc
abstract mixin class $AnalysisResultsCopyWith<$Res> implements $AnalysisStateCopyWith<$Res> {
  factory $AnalysisResultsCopyWith(AnalysisResults value, $Res Function(AnalysisResults) _then) = _$AnalysisResultsCopyWithImpl;
@useResult
$Res call({
 List<CategorySearchResult> categories, String query
});




}
/// @nodoc
class _$AnalysisResultsCopyWithImpl<$Res>
    implements $AnalysisResultsCopyWith<$Res> {
  _$AnalysisResultsCopyWithImpl(this._self, this._then);

  final AnalysisResults _self;
  final $Res Function(AnalysisResults) _then;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? query = null,}) {
  return _then(AnalysisResults(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategorySearchResult>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AnalysisEmpty implements AnalysisState {
  const AnalysisEmpty({required this.query});
  

 final  String query;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalysisEmptyCopyWith<AnalysisEmpty> get copyWith => _$AnalysisEmptyCopyWithImpl<AnalysisEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalysisEmpty&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'AnalysisState.empty(query: $query)';
}


}

/// @nodoc
abstract mixin class $AnalysisEmptyCopyWith<$Res> implements $AnalysisStateCopyWith<$Res> {
  factory $AnalysisEmptyCopyWith(AnalysisEmpty value, $Res Function(AnalysisEmpty) _then) = _$AnalysisEmptyCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$AnalysisEmptyCopyWithImpl<$Res>
    implements $AnalysisEmptyCopyWith<$Res> {
  _$AnalysisEmptyCopyWithImpl(this._self, this._then);

  final AnalysisEmpty _self;
  final $Res Function(AnalysisEmpty) _then;

/// Create a copy of AnalysisState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(AnalysisEmpty(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CategorySearchResult {

/// Full category value object — widget resolves display via
/// `categoryDisplayName(category, l10n)` (matches `TransactionTile`).
 Category get category; int get transactionCount; int get totalAmountMinorUnits; Currency get currency;/// `max(transaction.date)` within this `(category, currency)` group;
/// primary sort key in `AnalysisResults`.
 DateTime get mostRecentDate;
/// Create a copy of CategorySearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorySearchResultCopyWith<CategorySearchResult> get copyWith => _$CategorySearchResultCopyWithImpl<CategorySearchResult>(this as CategorySearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySearchResult&&(identical(other.category, category) || other.category == category)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.totalAmountMinorUnits, totalAmountMinorUnits) || other.totalAmountMinorUnits == totalAmountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.mostRecentDate, mostRecentDate) || other.mostRecentDate == mostRecentDate));
}


@override
int get hashCode => Object.hash(runtimeType,category,transactionCount,totalAmountMinorUnits,currency,mostRecentDate);

@override
String toString() {
  return 'CategorySearchResult(category: $category, transactionCount: $transactionCount, totalAmountMinorUnits: $totalAmountMinorUnits, currency: $currency, mostRecentDate: $mostRecentDate)';
}


}

/// @nodoc
abstract mixin class $CategorySearchResultCopyWith<$Res>  {
  factory $CategorySearchResultCopyWith(CategorySearchResult value, $Res Function(CategorySearchResult) _then) = _$CategorySearchResultCopyWithImpl;
@useResult
$Res call({
 Category category, int transactionCount, int totalAmountMinorUnits, Currency currency, DateTime mostRecentDate
});


$CategoryCopyWith<$Res> get category;$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$CategorySearchResultCopyWithImpl<$Res>
    implements $CategorySearchResultCopyWith<$Res> {
  _$CategorySearchResultCopyWithImpl(this._self, this._then);

  final CategorySearchResult _self;
  final $Res Function(CategorySearchResult) _then;

/// Create a copy of CategorySearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? transactionCount = null,Object? totalAmountMinorUnits = null,Object? currency = null,Object? mostRecentDate = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,totalAmountMinorUnits: null == totalAmountMinorUnits ? _self.totalAmountMinorUnits : totalAmountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,mostRecentDate: null == mostRecentDate ? _self.mostRecentDate : mostRecentDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of CategorySearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CategorySearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategorySearchResult].
extension CategorySearchResultPatterns on CategorySearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorySearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorySearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorySearchResult value)  $default,){
final _that = this;
switch (_that) {
case _CategorySearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorySearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _CategorySearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Category category,  int transactionCount,  int totalAmountMinorUnits,  Currency currency,  DateTime mostRecentDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorySearchResult() when $default != null:
return $default(_that.category,_that.transactionCount,_that.totalAmountMinorUnits,_that.currency,_that.mostRecentDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Category category,  int transactionCount,  int totalAmountMinorUnits,  Currency currency,  DateTime mostRecentDate)  $default,) {final _that = this;
switch (_that) {
case _CategorySearchResult():
return $default(_that.category,_that.transactionCount,_that.totalAmountMinorUnits,_that.currency,_that.mostRecentDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Category category,  int transactionCount,  int totalAmountMinorUnits,  Currency currency,  DateTime mostRecentDate)?  $default,) {final _that = this;
switch (_that) {
case _CategorySearchResult() when $default != null:
return $default(_that.category,_that.transactionCount,_that.totalAmountMinorUnits,_that.currency,_that.mostRecentDate);case _:
  return null;

}
}

}

/// @nodoc


class _CategorySearchResult implements CategorySearchResult {
  const _CategorySearchResult({required this.category, required this.transactionCount, required this.totalAmountMinorUnits, required this.currency, required this.mostRecentDate});
  

/// Full category value object — widget resolves display via
/// `categoryDisplayName(category, l10n)` (matches `TransactionTile`).
@override final  Category category;
@override final  int transactionCount;
@override final  int totalAmountMinorUnits;
@override final  Currency currency;
/// `max(transaction.date)` within this `(category, currency)` group;
/// primary sort key in `AnalysisResults`.
@override final  DateTime mostRecentDate;

/// Create a copy of CategorySearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorySearchResultCopyWith<_CategorySearchResult> get copyWith => __$CategorySearchResultCopyWithImpl<_CategorySearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorySearchResult&&(identical(other.category, category) || other.category == category)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.totalAmountMinorUnits, totalAmountMinorUnits) || other.totalAmountMinorUnits == totalAmountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.mostRecentDate, mostRecentDate) || other.mostRecentDate == mostRecentDate));
}


@override
int get hashCode => Object.hash(runtimeType,category,transactionCount,totalAmountMinorUnits,currency,mostRecentDate);

@override
String toString() {
  return 'CategorySearchResult(category: $category, transactionCount: $transactionCount, totalAmountMinorUnits: $totalAmountMinorUnits, currency: $currency, mostRecentDate: $mostRecentDate)';
}


}

/// @nodoc
abstract mixin class _$CategorySearchResultCopyWith<$Res> implements $CategorySearchResultCopyWith<$Res> {
  factory _$CategorySearchResultCopyWith(_CategorySearchResult value, $Res Function(_CategorySearchResult) _then) = __$CategorySearchResultCopyWithImpl;
@override @useResult
$Res call({
 Category category, int transactionCount, int totalAmountMinorUnits, Currency currency, DateTime mostRecentDate
});


@override $CategoryCopyWith<$Res> get category;@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$CategorySearchResultCopyWithImpl<$Res>
    implements _$CategorySearchResultCopyWith<$Res> {
  __$CategorySearchResultCopyWithImpl(this._self, this._then);

  final _CategorySearchResult _self;
  final $Res Function(_CategorySearchResult) _then;

/// Create a copy of CategorySearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? transactionCount = null,Object? totalAmountMinorUnits = null,Object? currency = null,Object? mostRecentDate = null,}) {
  return _then(_CategorySearchResult(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,totalAmountMinorUnits: null == totalAmountMinorUnits ? _self.totalAmountMinorUnits : totalAmountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,mostRecentDate: null == mostRecentDate ? _self.mostRecentDate : mostRecentDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CategorySearchResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CategorySearchResult
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
