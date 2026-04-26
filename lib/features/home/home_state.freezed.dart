// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState()';
}


}

/// @nodoc
class $HomeStateCopyWith<$Res>  {
$HomeStateCopyWith(HomeState _, $Res Function(HomeState) __);
}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HomeLoading value)?  loading,TResult Function( HomeEmpty value)?  empty,TResult Function( HomeData value)?  data,TResult Function( HomeError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading(_that);case HomeEmpty() when empty != null:
return empty(_that);case HomeData() when data != null:
return data(_that);case HomeError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HomeLoading value)  loading,required TResult Function( HomeEmpty value)  empty,required TResult Function( HomeData value)  data,required TResult Function( HomeError value)  error,}){
final _that = this;
switch (_that) {
case HomeLoading():
return loading(_that);case HomeEmpty():
return empty(_that);case HomeData():
return data(_that);case HomeError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HomeLoading value)?  loading,TResult? Function( HomeEmpty value)?  empty,TResult? Function( HomeData value)?  data,TResult? Function( HomeError value)?  error,}){
final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading(_that);case HomeEmpty() when empty != null:
return empty(_that);case HomeData() when data != null:
return data(_that);case HomeError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( DateTime selectedDay,  int pendingBadgeCount)?  empty,TResult Function( DateTime selectedDay,  List<DateTime> activityDays,  List<Transaction> transactionsForDay,  DailyTotals todayTotalsByCurrency,  Map<String, int> monthNetByCurrency,  DateTime? prevDayWithActivity,  DateTime? nextDayWithActivity,  int pendingBadgeCount,  PendingDelete? pendingDelete)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading();case HomeEmpty() when empty != null:
return empty(_that.selectedDay,_that.pendingBadgeCount);case HomeData() when data != null:
return data(_that.selectedDay,_that.activityDays,_that.transactionsForDay,_that.todayTotalsByCurrency,_that.monthNetByCurrency,_that.prevDayWithActivity,_that.nextDayWithActivity,_that.pendingBadgeCount,_that.pendingDelete);case HomeError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( DateTime selectedDay,  int pendingBadgeCount)  empty,required TResult Function( DateTime selectedDay,  List<DateTime> activityDays,  List<Transaction> transactionsForDay,  DailyTotals todayTotalsByCurrency,  Map<String, int> monthNetByCurrency,  DateTime? prevDayWithActivity,  DateTime? nextDayWithActivity,  int pendingBadgeCount,  PendingDelete? pendingDelete)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case HomeLoading():
return loading();case HomeEmpty():
return empty(_that.selectedDay,_that.pendingBadgeCount);case HomeData():
return data(_that.selectedDay,_that.activityDays,_that.transactionsForDay,_that.todayTotalsByCurrency,_that.monthNetByCurrency,_that.prevDayWithActivity,_that.nextDayWithActivity,_that.pendingBadgeCount,_that.pendingDelete);case HomeError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( DateTime selectedDay,  int pendingBadgeCount)?  empty,TResult? Function( DateTime selectedDay,  List<DateTime> activityDays,  List<Transaction> transactionsForDay,  DailyTotals todayTotalsByCurrency,  Map<String, int> monthNetByCurrency,  DateTime? prevDayWithActivity,  DateTime? nextDayWithActivity,  int pendingBadgeCount,  PendingDelete? pendingDelete)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading();case HomeEmpty() when empty != null:
return empty(_that.selectedDay,_that.pendingBadgeCount);case HomeData() when data != null:
return data(_that.selectedDay,_that.activityDays,_that.transactionsForDay,_that.todayTotalsByCurrency,_that.monthNetByCurrency,_that.prevDayWithActivity,_that.nextDayWithActivity,_that.pendingBadgeCount,_that.pendingDelete);case HomeError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class HomeLoading implements HomeState {
  const HomeLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.loading()';
}


}




/// @nodoc


class HomeEmpty implements HomeState {
  const HomeEmpty({required this.selectedDay, required this.pendingBadgeCount});
  

 final  DateTime selectedDay;
 final  int pendingBadgeCount;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeEmptyCopyWith<HomeEmpty> get copyWith => _$HomeEmptyCopyWithImpl<HomeEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeEmpty&&(identical(other.selectedDay, selectedDay) || other.selectedDay == selectedDay)&&(identical(other.pendingBadgeCount, pendingBadgeCount) || other.pendingBadgeCount == pendingBadgeCount));
}


@override
int get hashCode => Object.hash(runtimeType,selectedDay,pendingBadgeCount);

@override
String toString() {
  return 'HomeState.empty(selectedDay: $selectedDay, pendingBadgeCount: $pendingBadgeCount)';
}


}

/// @nodoc
abstract mixin class $HomeEmptyCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory $HomeEmptyCopyWith(HomeEmpty value, $Res Function(HomeEmpty) _then) = _$HomeEmptyCopyWithImpl;
@useResult
$Res call({
 DateTime selectedDay, int pendingBadgeCount
});




}
/// @nodoc
class _$HomeEmptyCopyWithImpl<$Res>
    implements $HomeEmptyCopyWith<$Res> {
  _$HomeEmptyCopyWithImpl(this._self, this._then);

  final HomeEmpty _self;
  final $Res Function(HomeEmpty) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? selectedDay = null,Object? pendingBadgeCount = null,}) {
  return _then(HomeEmpty(
selectedDay: null == selectedDay ? _self.selectedDay : selectedDay // ignore: cast_nullable_to_non_nullable
as DateTime,pendingBadgeCount: null == pendingBadgeCount ? _self.pendingBadgeCount : pendingBadgeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class HomeData implements HomeState {
  const HomeData({required this.selectedDay, required final  List<DateTime> activityDays, required final  List<Transaction> transactionsForDay, required final  DailyTotals todayTotalsByCurrency, required final  Map<String, int> monthNetByCurrency, required this.prevDayWithActivity, required this.nextDayWithActivity, required this.pendingBadgeCount, required this.pendingDelete}): _activityDays = activityDays,_transactionsForDay = transactionsForDay,_todayTotalsByCurrency = todayTotalsByCurrency,_monthNetByCurrency = monthNetByCurrency;
  

 final  DateTime selectedDay;
 final  List<DateTime> _activityDays;
 List<DateTime> get activityDays {
  if (_activityDays is EqualUnmodifiableListView) return _activityDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activityDays);
}

 final  List<Transaction> _transactionsForDay;
 List<Transaction> get transactionsForDay {
  if (_transactionsForDay is EqualUnmodifiableListView) return _transactionsForDay;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactionsForDay);
}

 final  DailyTotals _todayTotalsByCurrency;
 DailyTotals get todayTotalsByCurrency {
  if (_todayTotalsByCurrency is EqualUnmodifiableMapView) return _todayTotalsByCurrency;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_todayTotalsByCurrency);
}

 final  Map<String, int> _monthNetByCurrency;
 Map<String, int> get monthNetByCurrency {
  if (_monthNetByCurrency is EqualUnmodifiableMapView) return _monthNetByCurrency;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_monthNetByCurrency);
}

 final  DateTime? prevDayWithActivity;
 final  DateTime? nextDayWithActivity;
 final  int pendingBadgeCount;
 final  PendingDelete? pendingDelete;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeDataCopyWith<HomeData> get copyWith => _$HomeDataCopyWithImpl<HomeData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeData&&(identical(other.selectedDay, selectedDay) || other.selectedDay == selectedDay)&&const DeepCollectionEquality().equals(other._activityDays, _activityDays)&&const DeepCollectionEquality().equals(other._transactionsForDay, _transactionsForDay)&&const DeepCollectionEquality().equals(other._todayTotalsByCurrency, _todayTotalsByCurrency)&&const DeepCollectionEquality().equals(other._monthNetByCurrency, _monthNetByCurrency)&&(identical(other.prevDayWithActivity, prevDayWithActivity) || other.prevDayWithActivity == prevDayWithActivity)&&(identical(other.nextDayWithActivity, nextDayWithActivity) || other.nextDayWithActivity == nextDayWithActivity)&&(identical(other.pendingBadgeCount, pendingBadgeCount) || other.pendingBadgeCount == pendingBadgeCount)&&(identical(other.pendingDelete, pendingDelete) || other.pendingDelete == pendingDelete));
}


@override
int get hashCode => Object.hash(runtimeType,selectedDay,const DeepCollectionEquality().hash(_activityDays),const DeepCollectionEquality().hash(_transactionsForDay),const DeepCollectionEquality().hash(_todayTotalsByCurrency),const DeepCollectionEquality().hash(_monthNetByCurrency),prevDayWithActivity,nextDayWithActivity,pendingBadgeCount,pendingDelete);

@override
String toString() {
  return 'HomeState.data(selectedDay: $selectedDay, activityDays: $activityDays, transactionsForDay: $transactionsForDay, todayTotalsByCurrency: $todayTotalsByCurrency, monthNetByCurrency: $monthNetByCurrency, prevDayWithActivity: $prevDayWithActivity, nextDayWithActivity: $nextDayWithActivity, pendingBadgeCount: $pendingBadgeCount, pendingDelete: $pendingDelete)';
}


}

/// @nodoc
abstract mixin class $HomeDataCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory $HomeDataCopyWith(HomeData value, $Res Function(HomeData) _then) = _$HomeDataCopyWithImpl;
@useResult
$Res call({
 DateTime selectedDay, List<DateTime> activityDays, List<Transaction> transactionsForDay, DailyTotals todayTotalsByCurrency, Map<String, int> monthNetByCurrency, DateTime? prevDayWithActivity, DateTime? nextDayWithActivity, int pendingBadgeCount, PendingDelete? pendingDelete
});




}
/// @nodoc
class _$HomeDataCopyWithImpl<$Res>
    implements $HomeDataCopyWith<$Res> {
  _$HomeDataCopyWithImpl(this._self, this._then);

  final HomeData _self;
  final $Res Function(HomeData) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? selectedDay = null,Object? activityDays = null,Object? transactionsForDay = null,Object? todayTotalsByCurrency = null,Object? monthNetByCurrency = null,Object? prevDayWithActivity = freezed,Object? nextDayWithActivity = freezed,Object? pendingBadgeCount = null,Object? pendingDelete = freezed,}) {
  return _then(HomeData(
selectedDay: null == selectedDay ? _self.selectedDay : selectedDay // ignore: cast_nullable_to_non_nullable
as DateTime,activityDays: null == activityDays ? _self._activityDays : activityDays // ignore: cast_nullable_to_non_nullable
as List<DateTime>,transactionsForDay: null == transactionsForDay ? _self._transactionsForDay : transactionsForDay // ignore: cast_nullable_to_non_nullable
as List<Transaction>,todayTotalsByCurrency: null == todayTotalsByCurrency ? _self._todayTotalsByCurrency : todayTotalsByCurrency // ignore: cast_nullable_to_non_nullable
as DailyTotals,monthNetByCurrency: null == monthNetByCurrency ? _self._monthNetByCurrency : monthNetByCurrency // ignore: cast_nullable_to_non_nullable
as Map<String, int>,prevDayWithActivity: freezed == prevDayWithActivity ? _self.prevDayWithActivity : prevDayWithActivity // ignore: cast_nullable_to_non_nullable
as DateTime?,nextDayWithActivity: freezed == nextDayWithActivity ? _self.nextDayWithActivity : nextDayWithActivity // ignore: cast_nullable_to_non_nullable
as DateTime?,pendingBadgeCount: null == pendingBadgeCount ? _self.pendingBadgeCount : pendingBadgeCount // ignore: cast_nullable_to_non_nullable
as int,pendingDelete: freezed == pendingDelete ? _self.pendingDelete : pendingDelete // ignore: cast_nullable_to_non_nullable
as PendingDelete?,
  ));
}


}

/// @nodoc


class HomeError implements HomeState {
  const HomeError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeErrorCopyWith<HomeError> get copyWith => _$HomeErrorCopyWithImpl<HomeError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'HomeState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $HomeErrorCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory $HomeErrorCopyWith(HomeError value, $Res Function(HomeError) _then) = _$HomeErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$HomeErrorCopyWithImpl<$Res>
    implements $HomeErrorCopyWith<$Res> {
  _$HomeErrorCopyWithImpl(this._self, this._then);

  final HomeError _self;
  final $Res Function(HomeError) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(HomeError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
