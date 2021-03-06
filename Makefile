
include		 Makefile.rules

SRC		 = openvpn_radauth.c credentials.c
OBJS		 = $(SRC:.c=.o) libradius/libradius.a
PROG		 = $(SRC:.c=)$(SUFFIX)

STRIP		?= strip

CFLAGS		+= -I$(CURDIR)/libradius

ifeq ($(WITH_SSL_IMPL),polarssl)
LDFLAGS		+= -lpolarssl
else
ifeq ($(WITH_SSL_IMPL),openssl)
LDFLAGS		+= -lcrypto
else
ifeq ($(WITH_SSL_IMPL),mbedtls)
LDFLAGS		+= -lmbedcrypto
endif
endif
endif

export		WITH_SSL_IMPL

ifeq ($(filter -DHAVE_STRL,$(CFLAGS)),)
SRC		+= compat/strl.c
endif

OBJS		+= $(SRC:.c=.o)
PROG		 = $(firstword $(SRC:.c=))$(SUFFIX)

ifdef BUILD_DEBUG
CFLAGS		+= -DDEBUG
endif

ifdef BUILD_TEST
CFLAGS		+= -DOPENVPN_RADIUS_CONF=\"$(shell pwd)/test/radius.conf\"
endif

all:		clean $(PROG) strip

strip:		$(PROG)
ifndef DEBUG
		$(STRIP) $(PROG)
endif

%.o:		%.c
		$(CC) $(CFLAGS) -c -o $@ $<

compat/%.o:
		$(MAKE) -C compat

libradius/libradius.a:
		$(MAKE) -C libradius

$(PROG):	clean $(OBJS)
		$(CC) -o $(PROG) $(shell lorder $(OBJS) | tsort) $(LDFLAGS)

test:		clean
		$(MAKE) BUILD_TEST=1
		./test_build

clean:
		$(MAKE) -C compat clean
		$(MAKE) -C libradius clean
		-rm -f *.o core core.* $(PROG)

