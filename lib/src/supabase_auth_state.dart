import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/src/supabase.dart';
import 'package:supabase_flutter/src/supabase_lifecycle_state.dart';
import 'package:supabase_flutter/src/supabase_deep_linking_mixin.dart';

abstract class SupabaseAuthState<T extends StatefulWidget>
    extends SupabaseLifecycleState<T> with SupabaseDeepLinkingMixin {
  @override
  void initState() {
    super.initState();
    print('***** SupabaseAuthState initState');
    Supabase().client.auth.onAuthStateChange(_onAuthStateChange);
  }

  void _onAuthStateChange(AuthChangeEvent event, Session? session) {
    if (event == AuthChangeEvent.passwordRecovery && session != null) {
      onPasswordRecovery(session);
    }
  }

  @override
  void onHandledAuthDeeplink(Session session) {
    onAuthenticated(session);
  }

  @override
  void onErrorHandlingAuthDeeplink(String message) {
    onErrorAuthenticating(message);
  }

  /// This method helps recover/refresh session if it's available
  /// Should be called on a Splash screen when app starts.
  Future<bool> recoverSupabaseSession() async {
    final bool exist = await Supabase().hasAccessToken;
    if (!exist) {
      onUnauthenticated();
      return false;
    }

    final String? jsonStr = await Supabase().accessToken;
    if (jsonStr == null) {
      onUnauthenticated();
      return false;
    }

    final response = await Supabase().client.auth.recoverSession(jsonStr);
    if (response.error != null) {
      Supabase().removePersistSession();
      onUnauthenticated();
      return false;
    } else {
      onAuthenticated(response.data!);
      return true;
    }
  }

  @override
  Future<bool> onResumed() async {
    print('***** onResumed onResumed onResumed');
    final String? persistSessionString = await Supabase().accessToken;
    if (persistSessionString != null) {
      await Supabase().client.auth.recoverSession(persistSessionString);
    }
    return true;
  }

  void onUnauthenticated();
  void onAuthenticated(Session session);
  void onPasswordRecovery(Session session);
  void onErrorAuthenticating(String message);
}