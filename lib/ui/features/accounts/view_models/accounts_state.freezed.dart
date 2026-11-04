// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountWithBalance {

 Account get account; Map<String, int> get balancesByCurrency; AccountRowAffordance get affordance;
/// Create a copy of AccountWithBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountWithBalanceCopyWith<AccountWithBalance> get copyWith => _$AccountWithBalanceCopyWithImpl<AccountWithBalance>(this as AccountWithBalance, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AccountWithBalance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountWithBalance&&(identical(other.account, _this.account) || other.account == _this.account)&&const DeepCollectionEquality().equals(other.balancesByCurrency, _this.balancesByCurrency)&&(identical(other.affordance, _this.affordance) || other.affordance == _this.affordance));
}


@override
int get hashCode {
  final _this = this as AccountWithBalance;
  return Object.hash(runtimeType,_this.account,const DeepCollectionEquality().hash(_this.balancesByCurrency),_this.affordance);
}

@override
String toString() {
  final _this = this as AccountWithBalance;
  return 'AccountWithBalance(account: ${_this.account}, balancesByCurrency: ${_this.balancesByCurrency}, affordance: ${_this.affordance})';
}


}

/// @nodoc
abstract mixin class $AccountWithBalanceCopyWith<$Res>  {
  factory $AccountWithBalanceCopyWith(AccountWithBalance value, $Res Function(AccountWithBalance) _then) = _$AccountWithBalanceCopyWithImpl;
@useResult
$Res call({
 Account account, Map<String, int> balancesByCurrency, AccountRowAffordance affordance
});


$AccountCopyWith<$Res> get account;

}
/// @nodoc
class _$AccountWithBalanceCopyWithImpl<$Res>
    implements $AccountWithBalanceCopyWith<$Res> {
  _$AccountWithBalanceCopyWithImpl(this._self, this._then);

  final AccountWithBalance _self;
  final $Res Function(AccountWithBalance) _then;

/// Create a copy of AccountWithBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? account = null,Object? balancesByCurrency = null,Object? affordance = null,}) {
  return _then(AccountWithBalance(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as Account,balancesByCurrency: null == balancesByCurrency ? _self.balancesByCurrency : balancesByCurrency // ignore: cast_nullable_to_non_nullable
as Map<String, int>,affordance: null == affordance ? _self.affordance : affordance // ignore: cast_nullable_to_non_nullable
as AccountRowAffordance,
  ));
}
/// Create a copy of AccountWithBalance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountCopyWith<$Res> get account {
  
  return $AccountCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccountWithBalance].
extension AccountWithBalancePatterns on AccountWithBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountWithBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountWithBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountWithBalance value)  $default,){
final _that = this;
switch (_that) {
case _AccountWithBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountWithBalance value)?  $default,){
final _that = this;
switch (_that) {
case _AccountWithBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Account account,  Map<String, int> balancesByCurrency,  AccountRowAffordance affordance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountWithBalance() when $default != null:
return $default(_that.account,_that.balancesByCurrency,_that.affordance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Account account,  Map<String, int> balancesByCurrency,  AccountRowAffordance affordance)  $default,) {final _that = this;
switch (_that) {
case _AccountWithBalance():
return $default(_that.account,_that.balancesByCurrency,_that.affordance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Account account,  Map<String, int> balancesByCurrency,  AccountRowAffordance affordance)?  $default,) {final _that = this;
switch (_that) {
case _AccountWithBalance() when $default != null:
return $default(_that.account,_that.balancesByCurrency,_that.affordance);case _:
  return null;

}
}

}

/// @nodoc


class _AccountWithBalance implements AccountWithBalance {
  const _AccountWithBalance({required this.account, required  Map<String, int> balancesByCurrency, required this.affordance}): _balancesByCurrency = balancesByCurrency;
  

@override final  Account account;
 final  Map<String, int> _balancesByCurrency;
@override Map<String, int> get balancesByCurrency {
  if (_balancesByCurrency is EqualUnmodifiableMapView) return _balancesByCurrency;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_balancesByCurrency);
}

@override final  AccountRowAffordance affordance;

/// Create a copy of AccountWithBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountWithBalanceCopyWith<_AccountWithBalance> get copyWith => __$AccountWithBalanceCopyWithImpl<_AccountWithBalance>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountWithBalance&&(identical(other.account, account) || other.account == account)&&const DeepCollectionEquality().equals(other.balancesByCurrency, _balancesByCurrency)&&(identical(other.affordance, affordance) || other.affordance == affordance));
}


@override
int get hashCode {
    return Object.hash(runtimeType,account,const DeepCollectionEquality().hash(_balancesByCurrency),affordance);
}

@override
String toString() {
    return 'AccountWithBalance(account: $account, balancesByCurrency: $balancesByCurrency, affordance: $affordance)';
}


}

/// @nodoc
abstract mixin class _$AccountWithBalanceCopyWith<$Res> implements $AccountWithBalanceCopyWith<$Res> {
  factory _$AccountWithBalanceCopyWith(_AccountWithBalance value, $Res Function(_AccountWithBalance) _then) = __$AccountWithBalanceCopyWithImpl;
@override @useResult
$Res call({
 Account account, Map<String, int> balancesByCurrency, AccountRowAffordance affordance
});


@override $AccountCopyWith<$Res> get account;

}
/// @nodoc
class __$AccountWithBalanceCopyWithImpl<$Res>
    implements _$AccountWithBalanceCopyWith<$Res> {
  __$AccountWithBalanceCopyWithImpl(this._self, this._then);

  final _AccountWithBalance _self;
  final $Res Function(_AccountWithBalance) _then;

/// Create a copy of AccountWithBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? account = null,Object? balancesByCurrency = null,Object? affordance = null,}) {
  return _then(_AccountWithBalance(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as Account,balancesByCurrency: null == balancesByCurrency ? _self._balancesByCurrency : balancesByCurrency // ignore: cast_nullable_to_non_nullable
as Map<String, int>,affordance: null == affordance ? _self.affordance : affordance // ignore: cast_nullable_to_non_nullable
as AccountRowAffordance,
  ));
}

/// Create a copy of AccountWithBalance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountCopyWith<$Res> get account {
  
  return $AccountCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}

/// @nodoc
mixin _$AccountsState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccountsState()';
}


}

/// @nodoc
class $AccountsStateCopyWith<$Res>  {
$AccountsStateCopyWith(AccountsState _, $Res Function(AccountsState) __);
}


/// Adds pattern-matching-related methods to [AccountsState].
extension AccountsStatePatterns on AccountsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AccountsData value)?  data,TResult Function( AccountsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AccountsData() when data != null:
return data(_that);case AccountsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AccountsData value)  data,required TResult Function( AccountsError value)  error,}){
final _that = this;
switch (_that) {
case AccountsData():
return data(_that);case AccountsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AccountsData value)?  data,TResult? Function( AccountsError value)?  error,}){
final _that = this;
switch (_that) {
case AccountsData() when data != null:
return data(_that);case AccountsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<AccountWithBalance> active,  List<AccountWithBalance> archived,  int? defaultAccountId)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AccountsData() when data != null:
return data(_that.active,_that.archived,_that.defaultAccountId);case AccountsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<AccountWithBalance> active,  List<AccountWithBalance> archived,  int? defaultAccountId)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case AccountsData():
return data(_that.active,_that.archived,_that.defaultAccountId);case AccountsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<AccountWithBalance> active,  List<AccountWithBalance> archived,  int? defaultAccountId)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case AccountsData() when data != null:
return data(_that.active,_that.archived,_that.defaultAccountId);case AccountsError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class AccountsData implements AccountsState {
  const AccountsData({required  List<AccountWithBalance> active, required  List<AccountWithBalance> archived, required this.defaultAccountId}): _active = active,_archived = archived;
  

 final  List<AccountWithBalance> _active;
 List<AccountWithBalance> get active {
  if (_active is EqualUnmodifiableListView) return _active;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_active);
}

 final  List<AccountWithBalance> _archived;
 List<AccountWithBalance> get archived {
  if (_archived is EqualUnmodifiableListView) return _archived;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_archived);
}

 final  int? defaultAccountId;

/// Create a copy of AccountsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountsDataCopyWith<AccountsData> get copyWith => _$AccountsDataCopyWithImpl<AccountsData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountsData&&const DeepCollectionEquality().equals(other.active, _active)&&const DeepCollectionEquality().equals(other.archived, _archived)&&(identical(other.defaultAccountId, defaultAccountId) || other.defaultAccountId == defaultAccountId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_active),const DeepCollectionEquality().hash(_archived),defaultAccountId);
}

@override
String toString() {
    return 'AccountsState.data(active: $active, archived: $archived, defaultAccountId: $defaultAccountId)';
}


}

/// @nodoc
abstract mixin class $AccountsDataCopyWith<$Res> implements $AccountsStateCopyWith<$Res> {
  factory $AccountsDataCopyWith(AccountsData value, $Res Function(AccountsData) _then) = _$AccountsDataCopyWithImpl;
@useResult
$Res call({
 List<AccountWithBalance> active, List<AccountWithBalance> archived, int? defaultAccountId
});




}
/// @nodoc
class _$AccountsDataCopyWithImpl<$Res>
    implements $AccountsDataCopyWith<$Res> {
  _$AccountsDataCopyWithImpl(this._self, this._then);

  final AccountsData _self;
  final $Res Function(AccountsData) _then;

/// Create a copy of AccountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? active = null,Object? archived = null,Object? defaultAccountId = freezed,}) {
  return _then(AccountsData(
active: null == active ? _self._active : active // ignore: cast_nullable_to_non_nullable
as List<AccountWithBalance>,archived: null == archived ? _self._archived : archived // ignore: cast_nullable_to_non_nullable
as List<AccountWithBalance>,defaultAccountId: freezed == defaultAccountId ? _self.defaultAccountId : defaultAccountId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class AccountsError implements AccountsState {
  const AccountsError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of AccountsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountsErrorCopyWith<AccountsError> get copyWith => _$AccountsErrorCopyWithImpl<AccountsError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountsError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);
}

@override
String toString() {
    return 'AccountsState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $AccountsErrorCopyWith<$Res> implements $AccountsStateCopyWith<$Res> {
  factory $AccountsErrorCopyWith(AccountsError value, $Res Function(AccountsError) _then) = _$AccountsErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$AccountsErrorCopyWithImpl<$Res>
    implements $AccountsErrorCopyWith<$Res> {
  _$AccountsErrorCopyWithImpl(this._self, this._then);

  final AccountsError _self;
  final $Res Function(AccountsError) _then;

/// Create a copy of AccountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(AccountsError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

/// @nodoc
mixin _$SetDefaultAccountOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetDefaultAccountOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SetDefaultAccountOutcome()';
}


}

/// @nodoc
class $SetDefaultAccountOutcomeCopyWith<$Res>  {
$SetDefaultAccountOutcomeCopyWith(SetDefaultAccountOutcome _, $Res Function(SetDefaultAccountOutcome) __);
}


/// Adds pattern-matching-related methods to [SetDefaultAccountOutcome].
extension SetDefaultAccountOutcomePatterns on SetDefaultAccountOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SetDefaultAccountOk value)?  ok,TResult Function( SetDefaultAccountFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SetDefaultAccountOk() when ok != null:
return ok(_that);case SetDefaultAccountFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SetDefaultAccountOk value)  ok,required TResult Function( SetDefaultAccountFailed value)  failed,}){
final _that = this;
switch (_that) {
case SetDefaultAccountOk():
return ok(_that);case SetDefaultAccountFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SetDefaultAccountOk value)?  ok,TResult? Function( SetDefaultAccountFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SetDefaultAccountOk() when ok != null:
return ok(_that);case SetDefaultAccountFailed() when failed != null:
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
case SetDefaultAccountOk() when ok != null:
return ok();case SetDefaultAccountFailed() when failed != null:
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
case SetDefaultAccountOk():
return ok();case SetDefaultAccountFailed():
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
case SetDefaultAccountOk() when ok != null:
return ok();case SetDefaultAccountFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class SetDefaultAccountOk implements SetDefaultAccountOutcome {
  const SetDefaultAccountOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetDefaultAccountOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SetDefaultAccountOutcome.ok()';
}


}




/// @nodoc


class SetDefaultAccountFailed implements SetDefaultAccountOutcome {
  const SetDefaultAccountFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetDefaultAccountFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SetDefaultAccountOutcome.failed()';
}


}




/// @nodoc
mixin _$ArchiveAccountOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveAccountOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveAccountOutcome()';
}


}

/// @nodoc
class $ArchiveAccountOutcomeCopyWith<$Res>  {
$ArchiveAccountOutcomeCopyWith(ArchiveAccountOutcome _, $Res Function(ArchiveAccountOutcome) __);
}


/// Adds pattern-matching-related methods to [ArchiveAccountOutcome].
extension ArchiveAccountOutcomePatterns on ArchiveAccountOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ArchiveAccountOk value)?  ok,TResult Function( ArchiveAccountIsDefault value)?  isDefault,TResult Function( ArchiveAccountLastActive value)?  lastActive,TResult Function( ArchiveAccountHasActiveRecurringRule value)?  hasActiveRecurringRule,TResult Function( ArchiveAccountFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ArchiveAccountOk() when ok != null:
return ok(_that);case ArchiveAccountIsDefault() when isDefault != null:
return isDefault(_that);case ArchiveAccountLastActive() when lastActive != null:
return lastActive(_that);case ArchiveAccountHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule(_that);case ArchiveAccountFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ArchiveAccountOk value)  ok,required TResult Function( ArchiveAccountIsDefault value)  isDefault,required TResult Function( ArchiveAccountLastActive value)  lastActive,required TResult Function( ArchiveAccountHasActiveRecurringRule value)  hasActiveRecurringRule,required TResult Function( ArchiveAccountFailed value)  failed,}){
final _that = this;
switch (_that) {
case ArchiveAccountOk():
return ok(_that);case ArchiveAccountIsDefault():
return isDefault(_that);case ArchiveAccountLastActive():
return lastActive(_that);case ArchiveAccountHasActiveRecurringRule():
return hasActiveRecurringRule(_that);case ArchiveAccountFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ArchiveAccountOk value)?  ok,TResult? Function( ArchiveAccountIsDefault value)?  isDefault,TResult? Function( ArchiveAccountLastActive value)?  lastActive,TResult? Function( ArchiveAccountHasActiveRecurringRule value)?  hasActiveRecurringRule,TResult? Function( ArchiveAccountFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ArchiveAccountOk() when ok != null:
return ok(_that);case ArchiveAccountIsDefault() when isDefault != null:
return isDefault(_that);case ArchiveAccountLastActive() when lastActive != null:
return lastActive(_that);case ArchiveAccountHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule(_that);case ArchiveAccountFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  isDefault,TResult Function()?  lastActive,TResult Function()?  hasActiveRecurringRule,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ArchiveAccountOk() when ok != null:
return ok();case ArchiveAccountIsDefault() when isDefault != null:
return isDefault();case ArchiveAccountLastActive() when lastActive != null:
return lastActive();case ArchiveAccountHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule();case ArchiveAccountFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  isDefault,required TResult Function()  lastActive,required TResult Function()  hasActiveRecurringRule,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case ArchiveAccountOk():
return ok();case ArchiveAccountIsDefault():
return isDefault();case ArchiveAccountLastActive():
return lastActive();case ArchiveAccountHasActiveRecurringRule():
return hasActiveRecurringRule();case ArchiveAccountFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  isDefault,TResult? Function()?  lastActive,TResult? Function()?  hasActiveRecurringRule,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case ArchiveAccountOk() when ok != null:
return ok();case ArchiveAccountIsDefault() when isDefault != null:
return isDefault();case ArchiveAccountLastActive() when lastActive != null:
return lastActive();case ArchiveAccountHasActiveRecurringRule() when hasActiveRecurringRule != null:
return hasActiveRecurringRule();case ArchiveAccountFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class ArchiveAccountOk implements ArchiveAccountOutcome {
  const ArchiveAccountOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveAccountOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveAccountOutcome.ok()';
}


}




/// @nodoc


class ArchiveAccountIsDefault implements ArchiveAccountOutcome {
  const ArchiveAccountIsDefault();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveAccountIsDefault);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveAccountOutcome.isDefault()';
}


}




/// @nodoc


class ArchiveAccountLastActive implements ArchiveAccountOutcome {
  const ArchiveAccountLastActive();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveAccountLastActive);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveAccountOutcome.lastActive()';
}


}




/// @nodoc


class ArchiveAccountHasActiveRecurringRule implements ArchiveAccountOutcome {
  const ArchiveAccountHasActiveRecurringRule();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveAccountHasActiveRecurringRule);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveAccountOutcome.hasActiveRecurringRule()';
}


}




/// @nodoc


class ArchiveAccountFailed implements ArchiveAccountOutcome {
  const ArchiveAccountFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchiveAccountFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ArchiveAccountOutcome.failed()';
}


}




/// @nodoc
mixin _$UnarchiveAccountOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnarchiveAccountOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UnarchiveAccountOutcome()';
}


}

/// @nodoc
class $UnarchiveAccountOutcomeCopyWith<$Res>  {
$UnarchiveAccountOutcomeCopyWith(UnarchiveAccountOutcome _, $Res Function(UnarchiveAccountOutcome) __);
}


/// Adds pattern-matching-related methods to [UnarchiveAccountOutcome].
extension UnarchiveAccountOutcomePatterns on UnarchiveAccountOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UnarchiveAccountOk value)?  ok,TResult Function( UnarchiveAccountFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UnarchiveAccountOk() when ok != null:
return ok(_that);case UnarchiveAccountFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UnarchiveAccountOk value)  ok,required TResult Function( UnarchiveAccountFailed value)  failed,}){
final _that = this;
switch (_that) {
case UnarchiveAccountOk():
return ok(_that);case UnarchiveAccountFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UnarchiveAccountOk value)?  ok,TResult? Function( UnarchiveAccountFailed value)?  failed,}){
final _that = this;
switch (_that) {
case UnarchiveAccountOk() when ok != null:
return ok(_that);case UnarchiveAccountFailed() when failed != null:
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
case UnarchiveAccountOk() when ok != null:
return ok();case UnarchiveAccountFailed() when failed != null:
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
case UnarchiveAccountOk():
return ok();case UnarchiveAccountFailed():
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
case UnarchiveAccountOk() when ok != null:
return ok();case UnarchiveAccountFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class UnarchiveAccountOk implements UnarchiveAccountOutcome {
  const UnarchiveAccountOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnarchiveAccountOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UnarchiveAccountOutcome.ok()';
}


}




/// @nodoc


class UnarchiveAccountFailed implements UnarchiveAccountOutcome {
  const UnarchiveAccountFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnarchiveAccountFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UnarchiveAccountOutcome.failed()';
}


}




/// @nodoc
mixin _$DeleteAccountOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteAccountOutcome()';
}


}

/// @nodoc
class $DeleteAccountOutcomeCopyWith<$Res>  {
$DeleteAccountOutcomeCopyWith(DeleteAccountOutcome _, $Res Function(DeleteAccountOutcome) __);
}


/// Adds pattern-matching-related methods to [DeleteAccountOutcome].
extension DeleteAccountOutcomePatterns on DeleteAccountOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteAccountOk value)?  ok,TResult Function( DeleteAccountIsDefault value)?  isDefault,TResult Function( DeleteAccountInUse value)?  inUse,TResult Function( DeleteAccountFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteAccountOk() when ok != null:
return ok(_that);case DeleteAccountIsDefault() when isDefault != null:
return isDefault(_that);case DeleteAccountInUse() when inUse != null:
return inUse(_that);case DeleteAccountFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteAccountOk value)  ok,required TResult Function( DeleteAccountIsDefault value)  isDefault,required TResult Function( DeleteAccountInUse value)  inUse,required TResult Function( DeleteAccountFailed value)  failed,}){
final _that = this;
switch (_that) {
case DeleteAccountOk():
return ok(_that);case DeleteAccountIsDefault():
return isDefault(_that);case DeleteAccountInUse():
return inUse(_that);case DeleteAccountFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteAccountOk value)?  ok,TResult? Function( DeleteAccountIsDefault value)?  isDefault,TResult? Function( DeleteAccountInUse value)?  inUse,TResult? Function( DeleteAccountFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DeleteAccountOk() when ok != null:
return ok(_that);case DeleteAccountIsDefault() when isDefault != null:
return isDefault(_that);case DeleteAccountInUse() when inUse != null:
return inUse(_that);case DeleteAccountFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  isDefault,TResult Function()?  inUse,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeleteAccountOk() when ok != null:
return ok();case DeleteAccountIsDefault() when isDefault != null:
return isDefault();case DeleteAccountInUse() when inUse != null:
return inUse();case DeleteAccountFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  isDefault,required TResult Function()  inUse,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case DeleteAccountOk():
return ok();case DeleteAccountIsDefault():
return isDefault();case DeleteAccountInUse():
return inUse();case DeleteAccountFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  isDefault,TResult? Function()?  inUse,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case DeleteAccountOk() when ok != null:
return ok();case DeleteAccountIsDefault() when isDefault != null:
return isDefault();case DeleteAccountInUse() when inUse != null:
return inUse();case DeleteAccountFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class DeleteAccountOk implements DeleteAccountOutcome {
  const DeleteAccountOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteAccountOutcome.ok()';
}


}




/// @nodoc


class DeleteAccountIsDefault implements DeleteAccountOutcome {
  const DeleteAccountIsDefault();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountIsDefault);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteAccountOutcome.isDefault()';
}


}




/// @nodoc


class DeleteAccountInUse implements DeleteAccountOutcome {
  const DeleteAccountInUse();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountInUse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteAccountOutcome.inUse()';
}


}




/// @nodoc


class DeleteAccountFailed implements DeleteAccountOutcome {
  const DeleteAccountFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DeleteAccountOutcome.failed()';
}


}




/// @nodoc
mixin _$SaveAccountOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveAccountOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveAccountOutcome()';
}


}

/// @nodoc
class $SaveAccountOutcomeCopyWith<$Res>  {
$SaveAccountOutcomeCopyWith(SaveAccountOutcome _, $Res Function(SaveAccountOutcome) __);
}


/// Adds pattern-matching-related methods to [SaveAccountOutcome].
extension SaveAccountOutcomePatterns on SaveAccountOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveAccountOk value)?  ok,TResult Function( SaveAccountCurrencyLocked value)?  currencyLocked,TResult Function( SaveAccountFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveAccountOk() when ok != null:
return ok(_that);case SaveAccountCurrencyLocked() when currencyLocked != null:
return currencyLocked(_that);case SaveAccountFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveAccountOk value)  ok,required TResult Function( SaveAccountCurrencyLocked value)  currencyLocked,required TResult Function( SaveAccountFailed value)  failed,}){
final _that = this;
switch (_that) {
case SaveAccountOk():
return ok(_that);case SaveAccountCurrencyLocked():
return currencyLocked(_that);case SaveAccountFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveAccountOk value)?  ok,TResult? Function( SaveAccountCurrencyLocked value)?  currencyLocked,TResult? Function( SaveAccountFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SaveAccountOk() when ok != null:
return ok(_that);case SaveAccountCurrencyLocked() when currencyLocked != null:
return currencyLocked(_that);case SaveAccountFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int accountId)?  ok,TResult Function()?  currencyLocked,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveAccountOk() when ok != null:
return ok(_that.accountId);case SaveAccountCurrencyLocked() when currencyLocked != null:
return currencyLocked();case SaveAccountFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int accountId)  ok,required TResult Function()  currencyLocked,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case SaveAccountOk():
return ok(_that.accountId);case SaveAccountCurrencyLocked():
return currencyLocked();case SaveAccountFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int accountId)?  ok,TResult? Function()?  currencyLocked,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case SaveAccountOk() when ok != null:
return ok(_that.accountId);case SaveAccountCurrencyLocked() when currencyLocked != null:
return currencyLocked();case SaveAccountFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class SaveAccountOk implements SaveAccountOutcome {
  const SaveAccountOk(this.accountId);
  

 final  int accountId;

/// Create a copy of SaveAccountOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveAccountOkCopyWith<SaveAccountOk> get copyWith => _$SaveAccountOkCopyWithImpl<SaveAccountOk>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveAccountOk&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accountId);
}

@override
String toString() {
    return 'SaveAccountOutcome.ok(accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $SaveAccountOkCopyWith<$Res> implements $SaveAccountOutcomeCopyWith<$Res> {
  factory $SaveAccountOkCopyWith(SaveAccountOk value, $Res Function(SaveAccountOk) _then) = _$SaveAccountOkCopyWithImpl;
@useResult
$Res call({
 int accountId
});




}
/// @nodoc
class _$SaveAccountOkCopyWithImpl<$Res>
    implements $SaveAccountOkCopyWith<$Res> {
  _$SaveAccountOkCopyWithImpl(this._self, this._then);

  final SaveAccountOk _self;
  final $Res Function(SaveAccountOk) _then;

/// Create a copy of SaveAccountOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accountId = null,}) {
  return _then(SaveAccountOk(
null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SaveAccountCurrencyLocked implements SaveAccountOutcome {
  const SaveAccountCurrencyLocked();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveAccountCurrencyLocked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveAccountOutcome.currencyLocked()';
}


}




/// @nodoc


class SaveAccountFailed implements SaveAccountOutcome {
  const SaveAccountFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveAccountFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SaveAccountOutcome.failed()';
}


}




/// @nodoc
mixin _$CreateAccountTypeOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateAccountTypeOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CreateAccountTypeOutcome()';
}


}

/// @nodoc
class $CreateAccountTypeOutcomeCopyWith<$Res>  {
$CreateAccountTypeOutcomeCopyWith(CreateAccountTypeOutcome _, $Res Function(CreateAccountTypeOutcome) __);
}


/// Adds pattern-matching-related methods to [CreateAccountTypeOutcome].
extension CreateAccountTypeOutcomePatterns on CreateAccountTypeOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreateAccountTypeOk value)?  ok,TResult Function( CreateAccountTypeFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreateAccountTypeOk() when ok != null:
return ok(_that);case CreateAccountTypeFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreateAccountTypeOk value)  ok,required TResult Function( CreateAccountTypeFailed value)  failed,}){
final _that = this;
switch (_that) {
case CreateAccountTypeOk():
return ok(_that);case CreateAccountTypeFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreateAccountTypeOk value)?  ok,TResult? Function( CreateAccountTypeFailed value)?  failed,}){
final _that = this;
switch (_that) {
case CreateAccountTypeOk() when ok != null:
return ok(_that);case CreateAccountTypeFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AccountType accountType)?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreateAccountTypeOk() when ok != null:
return ok(_that.accountType);case CreateAccountTypeFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AccountType accountType)  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case CreateAccountTypeOk():
return ok(_that.accountType);case CreateAccountTypeFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AccountType accountType)?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case CreateAccountTypeOk() when ok != null:
return ok(_that.accountType);case CreateAccountTypeFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class CreateAccountTypeOk implements CreateAccountTypeOutcome {
  const CreateAccountTypeOk(this.accountType);
  

 final  AccountType accountType;

/// Create a copy of CreateAccountTypeOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateAccountTypeOkCopyWith<CreateAccountTypeOk> get copyWith => _$CreateAccountTypeOkCopyWithImpl<CreateAccountTypeOk>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateAccountTypeOk&&(identical(other.accountType, accountType) || other.accountType == accountType));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accountType);
}

@override
String toString() {
    return 'CreateAccountTypeOutcome.ok(accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class $CreateAccountTypeOkCopyWith<$Res> implements $CreateAccountTypeOutcomeCopyWith<$Res> {
  factory $CreateAccountTypeOkCopyWith(CreateAccountTypeOk value, $Res Function(CreateAccountTypeOk) _then) = _$CreateAccountTypeOkCopyWithImpl;
@useResult
$Res call({
 AccountType accountType
});


$AccountTypeCopyWith<$Res> get accountType;

}
/// @nodoc
class _$CreateAccountTypeOkCopyWithImpl<$Res>
    implements $CreateAccountTypeOkCopyWith<$Res> {
  _$CreateAccountTypeOkCopyWithImpl(this._self, this._then);

  final CreateAccountTypeOk _self;
  final $Res Function(CreateAccountTypeOk) _then;

/// Create a copy of CreateAccountTypeOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accountType = null,}) {
  return _then(CreateAccountTypeOk(
null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as AccountType,
  ));
}

/// Create a copy of CreateAccountTypeOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountTypeCopyWith<$Res> get accountType {
  
  return $AccountTypeCopyWith<$Res>(_self.accountType, (value) {
    return _then(_self.copyWith(accountType: value));
  });
}
}

/// @nodoc


class CreateAccountTypeFailed implements CreateAccountTypeOutcome {
  const CreateAccountTypeFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateAccountTypeFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CreateAccountTypeOutcome.failed()';
}


}




// dart format on
