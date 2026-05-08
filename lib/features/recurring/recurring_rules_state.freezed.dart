// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rules_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurringRulesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRulesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecurringRulesState()';
}


}

/// @nodoc
class $RecurringRulesStateCopyWith<$Res>  {
$RecurringRulesStateCopyWith(RecurringRulesState _, $Res Function(RecurringRulesState) __);
}


/// Adds pattern-matching-related methods to [RecurringRulesState].
extension RecurringRulesStatePatterns on RecurringRulesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RecurringRulesLoading value)?  loading,TResult Function( RecurringRulesEmpty value)?  empty,TResult Function( RecurringRulesData value)?  data,TResult Function( RecurringRulesError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RecurringRulesLoading() when loading != null:
return loading(_that);case RecurringRulesEmpty() when empty != null:
return empty(_that);case RecurringRulesData() when data != null:
return data(_that);case RecurringRulesError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RecurringRulesLoading value)  loading,required TResult Function( RecurringRulesEmpty value)  empty,required TResult Function( RecurringRulesData value)  data,required TResult Function( RecurringRulesError value)  error,}){
final _that = this;
switch (_that) {
case RecurringRulesLoading():
return loading(_that);case RecurringRulesEmpty():
return empty(_that);case RecurringRulesData():
return data(_that);case RecurringRulesError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RecurringRulesLoading value)?  loading,TResult? Function( RecurringRulesEmpty value)?  empty,TResult? Function( RecurringRulesData value)?  data,TResult? Function( RecurringRulesError value)?  error,}){
final _that = this;
switch (_that) {
case RecurringRulesLoading() when loading != null:
return loading(_that);case RecurringRulesEmpty() when empty != null:
return empty(_that);case RecurringRulesData() when data != null:
return data(_that);case RecurringRulesError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  empty,TResult Function( List<RecurringRule> rules,  RecurringRulesPendingDelete? pendingDelete)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RecurringRulesLoading() when loading != null:
return loading();case RecurringRulesEmpty() when empty != null:
return empty();case RecurringRulesData() when data != null:
return data(_that.rules,_that.pendingDelete);case RecurringRulesError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  empty,required TResult Function( List<RecurringRule> rules,  RecurringRulesPendingDelete? pendingDelete)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case RecurringRulesLoading():
return loading();case RecurringRulesEmpty():
return empty();case RecurringRulesData():
return data(_that.rules,_that.pendingDelete);case RecurringRulesError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  empty,TResult? Function( List<RecurringRule> rules,  RecurringRulesPendingDelete? pendingDelete)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case RecurringRulesLoading() when loading != null:
return loading();case RecurringRulesEmpty() when empty != null:
return empty();case RecurringRulesData() when data != null:
return data(_that.rules,_that.pendingDelete);case RecurringRulesError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class RecurringRulesLoading implements RecurringRulesState {
  const RecurringRulesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRulesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecurringRulesState.loading()';
}


}




/// @nodoc


class RecurringRulesEmpty implements RecurringRulesState {
  const RecurringRulesEmpty();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRulesEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecurringRulesState.empty()';
}


}




/// @nodoc


class RecurringRulesData implements RecurringRulesState {
  const RecurringRulesData({required final  List<RecurringRule> rules, required this.pendingDelete}): _rules = rules;
  

 final  List<RecurringRule> _rules;
 List<RecurringRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

 final  RecurringRulesPendingDelete? pendingDelete;

/// Create a copy of RecurringRulesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringRulesDataCopyWith<RecurringRulesData> get copyWith => _$RecurringRulesDataCopyWithImpl<RecurringRulesData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRulesData&&const DeepCollectionEquality().equals(other._rules, _rules)&&(identical(other.pendingDelete, pendingDelete) || other.pendingDelete == pendingDelete));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rules),pendingDelete);

@override
String toString() {
  return 'RecurringRulesState.data(rules: $rules, pendingDelete: $pendingDelete)';
}


}

/// @nodoc
abstract mixin class $RecurringRulesDataCopyWith<$Res> implements $RecurringRulesStateCopyWith<$Res> {
  factory $RecurringRulesDataCopyWith(RecurringRulesData value, $Res Function(RecurringRulesData) _then) = _$RecurringRulesDataCopyWithImpl;
@useResult
$Res call({
 List<RecurringRule> rules, RecurringRulesPendingDelete? pendingDelete
});




}
/// @nodoc
class _$RecurringRulesDataCopyWithImpl<$Res>
    implements $RecurringRulesDataCopyWith<$Res> {
  _$RecurringRulesDataCopyWithImpl(this._self, this._then);

  final RecurringRulesData _self;
  final $Res Function(RecurringRulesData) _then;

/// Create a copy of RecurringRulesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rules = null,Object? pendingDelete = freezed,}) {
  return _then(RecurringRulesData(
rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<RecurringRule>,pendingDelete: freezed == pendingDelete ? _self.pendingDelete : pendingDelete // ignore: cast_nullable_to_non_nullable
as RecurringRulesPendingDelete?,
  ));
}


}

/// @nodoc


class RecurringRulesError implements RecurringRulesState {
  const RecurringRulesError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of RecurringRulesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringRulesErrorCopyWith<RecurringRulesError> get copyWith => _$RecurringRulesErrorCopyWithImpl<RecurringRulesError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRulesError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'RecurringRulesState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $RecurringRulesErrorCopyWith<$Res> implements $RecurringRulesStateCopyWith<$Res> {
  factory $RecurringRulesErrorCopyWith(RecurringRulesError value, $Res Function(RecurringRulesError) _then) = _$RecurringRulesErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$RecurringRulesErrorCopyWithImpl<$Res>
    implements $RecurringRulesErrorCopyWith<$Res> {
  _$RecurringRulesErrorCopyWithImpl(this._self, this._then);

  final RecurringRulesError _self;
  final $Res Function(RecurringRulesError) _then;

/// Create a copy of RecurringRulesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(RecurringRulesError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
