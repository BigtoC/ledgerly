// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountWithBalance&&(identical(other.account, account) || other.account == account)&&const DeepCollectionEquality().equals(other.balancesByCurrency, balancesByCurrency)&&(identical(other.affordance, affordance) || other.affordance == affordance));
}


@override
int get hashCode => Object.hash(runtimeType,account,const DeepCollectionEquality().hash(balancesByCurrency),affordance);

@override
String toString() {
  return 'AccountWithBalance(account: $account, balancesByCurrency: $balancesByCurrency, affordance: $affordance)';
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
  return _then(_self.copyWith(
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
  const _AccountWithBalance({required this.account, required final  Map<String, int> balancesByCurrency, required this.affordance}): _balancesByCurrency = balancesByCurrency;
  

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountWithBalance&&(identical(other.account, account) || other.account == account)&&const DeepCollectionEquality().equals(other._balancesByCurrency, _balancesByCurrency)&&(identical(other.affordance, affordance) || other.affordance == affordance));
}


@override
int get hashCode => Object.hash(runtimeType,account,const DeepCollectionEquality().hash(_balancesByCurrency),affordance);

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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AccountsLoading value)?  loading,TResult Function( AccountsData value)?  data,TResult Function( AccountsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AccountsLoading() when loading != null:
return loading(_that);case AccountsData() when data != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AccountsLoading value)  loading,required TResult Function( AccountsData value)  data,required TResult Function( AccountsError value)  error,}){
final _that = this;
switch (_that) {
case AccountsLoading():
return loading(_that);case AccountsData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AccountsLoading value)?  loading,TResult? Function( AccountsData value)?  data,TResult? Function( AccountsError value)?  error,}){
final _that = this;
switch (_that) {
case AccountsLoading() when loading != null:
return loading(_that);case AccountsData() when data != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<AccountWithBalance> active,  List<AccountWithBalance> archived,  int? defaultAccountId)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AccountsLoading() when loading != null:
return loading();case AccountsData() when data != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<AccountWithBalance> active,  List<AccountWithBalance> archived,  int? defaultAccountId)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case AccountsLoading():
return loading();case AccountsData():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<AccountWithBalance> active,  List<AccountWithBalance> archived,  int? defaultAccountId)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case AccountsLoading() when loading != null:
return loading();case AccountsData() when data != null:
return data(_that.active,_that.archived,_that.defaultAccountId);case AccountsError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class AccountsLoading implements AccountsState {
  const AccountsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountsState.loading()';
}


}




/// @nodoc


class AccountsData implements AccountsState {
  const AccountsData({required final  List<AccountWithBalance> active, required final  List<AccountWithBalance> archived, required this.defaultAccountId}): _active = active,_archived = archived;
  

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountsData&&const DeepCollectionEquality().equals(other._active, _active)&&const DeepCollectionEquality().equals(other._archived, _archived)&&(identical(other.defaultAccountId, defaultAccountId) || other.defaultAccountId == defaultAccountId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_active),const DeepCollectionEquality().hash(_archived),defaultAccountId);

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
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

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

// dart format on
