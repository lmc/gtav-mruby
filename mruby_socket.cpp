
bool initWSA() {
	WSADATA wsadata;
	int error = WSAStartup(0x0202, &wsadata);
	if (error) return false;
	return true;
}

mrb_value mruby__gtav__socket_init(mrb_state *mrb, mrb_value self) {
	return mrb_bool_value(initWSA());
}


mrb_value mruby__gtav__socket_listen(mrb_state *mrb, mrb_value self) {
	mrb_int port;
	mrb_get_args(mrb, "i", &port);

	SOCKET ss;
	SOCKADDR_IN addr;
	addr.sin_family = AF_INET;
	addr.sin_port = htons(port);
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	ss = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

	u_long nonblocking = 1;
	ioctlsocket(ss, FIONBIO, &nonblocking);

	char message[128];

	//fprintf(stdout, "socket %i\n", ss);

	int bi = bind(ss, (LPSOCKADDR)&addr, sizeof(addr));
	//fprintf(stdout, "bind %i\n", bi);
	if (bi < 0) {
		sprintf(message, "bind error %i", bi);
		mrb_raise(mrb, mrb_class_get(mrb, "RuntimeError"), message);
		return mrb_nil_value();
	}

	int li = listen(ss, 3);
	//fprintf(stdout, "listen %i\n", li);
	if (li < 0) {
		sprintf(message, "listen error %i", li);
		mrb_raise(mrb, mrb_class_get(mrb, "RuntimeError"), message);
		return mrb_nil_value();
	}

	return mrb_fixnum_value(ss);
}

mrb_value mruby__gtav__socket_accept(mrb_state *mrb, mrb_value self) {
	SOCKET ss;
	mrb_get_args(mrb, "i", &ss);
	char message[128];

	SOCKET sss = accept(ss, NULL, NULL);
	if (sss == INVALID_SOCKET) {
		return mrb_nil_value();
	}
	else if (sss < 0) {
		sprintf(message, "accept error %i", sss);
		mrb_raise(mrb, mrb_class_get(mrb, "RuntimeError"), message);
		return mrb_nil_value();
	}
	else {
		// TODO: do we need to set nonblocking?
		return mrb_fixnum_value(sss);
	}
}

mrb_value mruby__gtav__socket_read(mrb_state *mrb, mrb_value self) {
	SOCKET ss;
	mrb_get_args(mrb, "i", &ss);
	char recvbuffer[1024];
	memset(&recvbuffer[0], 0, sizeof(recvbuffer));
	int ri = recv(ss, recvbuffer, sizeof(recvbuffer), 0);
	if (ri < 0) {
		return mrb_fixnum_value(ri);
	}
	else {
		return mrb_str_new_cstr(mrb, recvbuffer);
	}
}

mrb_value mruby__gtav__socket_write(mrb_state *mrb, mrb_value self) {
	SOCKET ss;
	char *str;
	int str_len;
	mrb_get_args(mrb, "is", &ss, &str, &str_len);
	int wi = send(ss, str, strlen(str), NULL);
	if (wi < 0) {
		return mrb_fixnum_value(wi);
	}
	else {
		return mrb_true_value();
	}
}

mrb_value mruby__gtav__socket_close(mrb_state *mrb, mrb_value self) {
	SOCKET ss;
	mrb_get_args(mrb, "i", &ss);
	closesocket(ss);
	return mrb_true_value();
}

