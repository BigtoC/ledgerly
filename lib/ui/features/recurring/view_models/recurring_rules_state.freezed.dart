// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rules_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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
  const RecurringRulesData({required  List<RecurringRule> rules, required this.pendingDelete}): _rules = rules;
  

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRulesData&&const DeepCollectionEquality().equals(other.rules, _rules)&&(identical(other.pendingDelete, pendingDelete) || other.pendingDelete == pendingDelete));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_rules),pendingDelete);
}

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
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);
}

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

/// @nodoc
mixin _$PauseRecurringRuleOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseRecurringRuleOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PauseRecurringRuleOutcome()';
}


}

/// @nodoc
class $PauseRecurringRuleOutcomeCopyWith<$Res>  {
$PauseRecurringRuleOutcomeCopyWith(PauseRecurringRuleOutcome _, $Res Function(PauseRecurringRuleOutcome) __);
}


/// Adds pattern-matching-related methods to [PauseRecurringRuleOutcome].
extension PauseRecurringRuleOutcomePatterns on PauseRecurringRuleOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PauseRecurringRuleOk value)?  ok,TResult Function( PauseRecurringRuleFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PauseRecurringRuleOk() when ok != null:
return ok(_that);case PauseRecurringRuleFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PauseRecurringRuleOk value)  ok,required TResult Function( PauseRecurringRuleFailed value)  failed,}){
final _that = this;
switch (_that) {
case PauseRecurringRuleOk():
return ok(_that);case PauseRecurringRuleFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PauseRecurringRuleOk value)?  ok,TResult? Function( PauseRecurringRuleFailed value)?  failed,}){
final _that = this;
switch (_that) {
case PauseRecurringRuleOk() when ok != null:
return ok(_that);case PauseRecurringRuleFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PauseRecurringRuleOk() when ok != null:
return ok();case PauseRecurringRuleFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case PauseRecurringRuleOk():
return ok();case PauseRecurringRuleFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case PauseRecurringRuleOk() when ok != null:
return ok();case PauseRecurringRuleFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class PauseRecurringRuleOk implements PauseRecurringRuleOutcome {
  const PauseRecurringRuleOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseRecurringRuleOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PauseRecurringRuleOutcome.ok()';
}


}




/// @nodoc


class PauseRecurringRuleFailed implements PauseRecurringRuleOutcome {
  const PauseRecurringRuleFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PauseRecurringRuleFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'PauseRecurringRuleOutcome.failed()';
}


}




/// @nodoc
mixin _$ResumeRecurringRuleOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResumeRecurringRuleOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ResumeRecurringRuleOutcome()';
}


}

/// @nodoc
class $ResumeRecurringRuleOutcomeCopyWith<$Res>  {
$ResumeRecurringRuleOutcomeCopyWith(ResumeRecurringRuleOutcome _, $Res Function(ResumeRecurringRuleOutcome) __);
}


/// Adds pattern-matching-related methods to [ResumeRecurringRuleOutcome].
extension ResumeRecurringRuleOutcomePatterns on ResumeRecurringRuleOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ResumeRecurringRuleOk value)?  ok,TResult Function( ResumeRecurringRuleFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ResumeRecurringRuleOk() when ok != null:
return ok(_that);case ResumeRecurringRuleFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ResumeRecurringRuleOk value)  ok,required TResult Function( ResumeRecurringRuleFailed value)  failed,}){
final _that = this;
switch (_that) {
case ResumeRecurringRuleOk():
return ok(_that);case ResumeRecurringRuleFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ResumeRecurringRuleOk value)?  ok,TResult? Function( ResumeRecurringRuleFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ResumeRecurringRuleOk() when ok != null:
return ok(_that);case ResumeRecurringRuleFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DateTime? nextDueDate)?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ResumeRecurringRuleOk() when ok != null:
return ok(_that.nextDueDate);case ResumeRecurringRuleFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DateTime? nextDueDate)  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case ResumeRecurringRuleOk():
return ok(_that.nextDueDate);case ResumeRecurringRuleFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DateTime? nextDueDate)?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case ResumeRecurringRuleOk() when ok != null:
return ok(_that.nextDueDate);case ResumeRecurringRuleFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class ResumeRecurringRuleOk implements ResumeRecurringRuleOutcome {
  const ResumeRecurringRuleOk(this.nextDueDate);
  

 final  DateTime? nextDueDate;

/// Create a copy of ResumeRecurringRuleOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResumeRecurringRuleOkCopyWith<ResumeRecurringRuleOk> get copyWith => _$ResumeRecurringRuleOkCopyWithImpl<ResumeRecurringRuleOk>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResumeRecurringRuleOk&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,nextDueDate);
}

@override
String toString() {
    return 'ResumeRecurringRuleOutcome.ok(nextDueDate: $nextDueDate)';
}


}

/// @nodoc
abstract mixin class $ResumeRecurringRuleOkCopyWith<$Res> implements $ResumeRecurringRuleOutcomeCopyWith<$Res> {
  factory $ResumeRecurringRuleOkCopyWith(ResumeRecurringRuleOk value, $Res Function(ResumeRecurringRuleOk) _then) = _$ResumeRecurringRuleOkCopyWithImpl;
@useResult
$Res call({
 DateTime? nextDueDate
});




}
/// @nodoc
class _$ResumeRecurringRuleOkCopyWithImpl<$Res>
    implements $ResumeRecurringRuleOkCopyWith<$Res> {
  _$ResumeRecurringRuleOkCopyWithImpl(this._self, this._then);

  final ResumeRecurringRuleOk _self;
  final $Res Function(ResumeRecurringRuleOk) _then;

/// Create a copy of ResumeRecurringRuleOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? nextDueDate = freezed,}) {
  return _then(ResumeRecurringRuleOk(
freezed == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class ResumeRecurringRuleFailed implements ResumeRecurringRuleOutcome {
  const ResumeRecurringRuleFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResumeRecurringRuleFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ResumeRecurringRuleOutcome.failed()';
}


}




/// @nodoc
mixin _$DeleteRecurringRuleOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteRecurringRuleOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteRecurringRuleOutcome()';
}


}

/// @nodoc
class $DeleteRecurringRuleOutcomeCopyWith<$Res>  {
$DeleteRecurringRuleOutcomeCopyWith(DeleteRecurringRuleOutcome _, $Res Function(DeleteRecurringRuleOutcome) __);
}


/// Adds pattern-matching-related methods to [DeleteRecurringRuleOutcome].
extension DeleteRecurringRuleOutcomePatterns on DeleteRecurringRuleOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteRecurringRulePending value)?  pending,TResult Function( DeleteRecurringRuleNotStarted value)?  notStarted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteRecurringRulePending() when pending != null:
return pending(_that);case DeleteRecurringRuleNotStarted() when notStarted != null:
return notStarted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteRecurringRulePending value)  pending,required TResult Function( DeleteRecurringRuleNotStarted value)  notStarted,}){
final _that = this;
switch (_that) {
case DeleteRecurringRulePending():
return pending(_that);case DeleteRecurringRuleNotStarted():
return notStarted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteRecurringRulePending value)?  pending,TResult? Function( DeleteRecurringRuleNotStarted value)?  notStarted,}){
final _that = this;
switch (_that) {
case DeleteRecurringRulePending() when pending != null:
return pending(_that);case DeleteRecurringRuleNotStarted() when notStarted != null:
return notStarted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function()?  notStarted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeleteRecurringRulePending() when pending != null:
return pending();case DeleteRecurringRuleNotStarted() when notStarted != null:
return notStarted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function()  notStarted,}) {final _that = this;
switch (_that) {
case DeleteRecurringRulePending():
return pending();case DeleteRecurringRuleNotStarted():
return notStarted();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function()?  notStarted,}) {final _that = this;
switch (_that) {
case DeleteRecurringRulePending() when pending != null:
return pending();case DeleteRecurringRuleNotStarted() when notStarted != null:
return notStarted();case _:
  return null;

}
}

}

/// @nodoc


class DeleteRecurringRulePending implements DeleteRecurringRuleOutcome {
  const DeleteRecurringRulePending();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteRecurringRulePending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteRecurringRuleOutcome.pending()';
}


}




/// @nodoc


class DeleteRecurringRuleNotStarted implements DeleteRecurringRuleOutcome {
  const DeleteRecurringRuleNotStarted();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteRecurringRuleNotStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteRecurringRuleOutcome.notStarted()';
}


}




// dart format on
