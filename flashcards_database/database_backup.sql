--
-- PostgreSQL database dump
--

\restrict MChfUZZ0x5iQOpXgOA1xMIKrSh5XbNYJntPM4icsi1SivJXWTLgVUeYHijqNVI1

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS myapp;
--
-- Name: myapp; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE myapp WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE myapp OWNER TO postgres;

\unrestrict MChfUZZ0x5iQOpXgOA1xMIKrSh5XbNYJntPM4icsi1SivJXWTLgVUeYHijqNVI1
\connect myapp
\restrict MChfUZZ0x5iQOpXgOA1xMIKrSh5XbNYJntPM4icsi1SivJXWTLgVUeYHijqNVI1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    description text,
    parent_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.categories OWNER TO appuser;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO appuser;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: flashcards; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.flashcards (
    id integer NOT NULL,
    list_id integer,
    category_id integer,
    base_word text NOT NULL,
    translation text NOT NULL,
    pos text,
    example_sentence text,
    example_translation text,
    difficulty smallint DEFAULT 1 NOT NULL,
    tags text[],
    audio_url text,
    extra jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.flashcards OWNER TO appuser;

--
-- Name: flashcards_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.flashcards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.flashcards_id_seq OWNER TO appuser;

--
-- Name: flashcards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.flashcards_id_seq OWNED BY public.flashcards.id;


--
-- Name: quiz_attempts; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.quiz_attempts (
    id bigint NOT NULL,
    quiz_id bigint,
    user_id uuid,
    card_id integer,
    is_correct boolean NOT NULL,
    choice_a text,
    choice_b text,
    choice_c text,
    choice_d text,
    correct_choice character(1),
    response_choice character(1),
    response_time_ms integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.quiz_attempts OWNER TO appuser;

--
-- Name: quiz_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.quiz_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quiz_attempts_id_seq OWNER TO appuser;

--
-- Name: quiz_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.quiz_attempts_id_seq OWNED BY public.quiz_attempts.id;


--
-- Name: quizzes; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.quizzes (
    id bigint NOT NULL,
    user_id uuid,
    mode text NOT NULL,
    direction smallint DEFAULT 0 NOT NULL,
    category_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.quizzes OWNER TO appuser;

--
-- Name: quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.quizzes_id_seq OWNER TO appuser;

--
-- Name: quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.quizzes_id_seq OWNED BY public.quizzes.id;


--
-- Name: review_logs; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.review_logs (
    id bigint NOT NULL,
    user_id uuid,
    card_id integer,
    direction smallint DEFAULT 0 NOT NULL,
    rating smallint NOT NULL,
    prev_ease numeric(4,2),
    new_ease numeric(4,2),
    prev_interval integer,
    new_interval integer,
    reviewed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.review_logs OWNER TO appuser;

--
-- Name: review_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.review_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.review_logs_id_seq OWNER TO appuser;

--
-- Name: review_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.review_logs_id_seq OWNED BY public.review_logs.id;


--
-- Name: user_flashcards; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.user_flashcards (
    id bigint NOT NULL,
    user_id uuid,
    card_id integer,
    direction smallint DEFAULT 0 NOT NULL,
    last_reviewed_at timestamp with time zone,
    next_review_at timestamp with time zone,
    ease_factor numeric(4,2) DEFAULT 2.50 NOT NULL,
    interval_days integer DEFAULT 0 NOT NULL,
    reps integer DEFAULT 0 NOT NULL,
    lapses integer DEFAULT 0 NOT NULL,
    status smallint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_flashcards OWNER TO appuser;

--
-- Name: user_flashcards_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.user_flashcards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_flashcards_id_seq OWNER TO appuser;

--
-- Name: user_flashcards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.user_flashcards_id_seq OWNED BY public.user_flashcards.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email public.citext NOT NULL,
    username character varying(50),
    password_hash text,
    auth_provider character varying(20) DEFAULT 'local'::character varying NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO appuser;

--
-- Name: word_lists; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.word_lists (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    language_from text DEFAULT 'en'::text NOT NULL,
    language_to text DEFAULT 'id'::text NOT NULL,
    source text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.word_lists OWNER TO appuser;

--
-- Name: word_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.word_lists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.word_lists_id_seq OWNER TO appuser;

--
-- Name: word_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.word_lists_id_seq OWNED BY public.word_lists.id;


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: flashcards id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.flashcards ALTER COLUMN id SET DEFAULT nextval('public.flashcards_id_seq'::regclass);


--
-- Name: quiz_attempts id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quiz_attempts ALTER COLUMN id SET DEFAULT nextval('public.quiz_attempts_id_seq'::regclass);


--
-- Name: quizzes id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quizzes ALTER COLUMN id SET DEFAULT nextval('public.quizzes_id_seq'::regclass);


--
-- Name: review_logs id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.review_logs ALTER COLUMN id SET DEFAULT nextval('public.review_logs_id_seq'::regclass);


--
-- Name: user_flashcards id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.user_flashcards ALTER COLUMN id SET DEFAULT nextval('public.user_flashcards_id_seq'::regclass);


--
-- Name: word_lists id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.word_lists ALTER COLUMN id SET DEFAULT nextval('public.word_lists_id_seq'::regclass);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.categories (id, slug, name, description, parent_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: flashcards; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.flashcards (id, list_id, category_id, base_word, translation, pos, example_sentence, example_translation, difficulty, tags, audio_url, extra, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: quiz_attempts; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.quiz_attempts (id, quiz_id, user_id, card_id, is_correct, choice_a, choice_b, choice_c, choice_d, correct_choice, response_choice, response_time_ms, created_at) FROM stdin;
\.


--
-- Data for Name: quizzes; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.quizzes (id, user_id, mode, direction, category_id, created_at) FROM stdin;
\.


--
-- Data for Name: review_logs; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.review_logs (id, user_id, card_id, direction, rating, prev_ease, new_ease, prev_interval, new_interval, reviewed_at) FROM stdin;
\.


--
-- Data for Name: user_flashcards; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.user_flashcards (id, user_id, card_id, direction, last_reviewed_at, next_review_at, ease_factor, interval_days, reps, lapses, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.users (id, email, username, password_hash, auth_provider, settings, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: word_lists; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.word_lists (id, name, description, language_from, language_to, source, created_at, updated_at) FROM stdin;
\.


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.categories_id_seq', 1, false);


--
-- Name: flashcards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.flashcards_id_seq', 1, false);


--
-- Name: quiz_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.quiz_attempts_id_seq', 1, false);


--
-- Name: quizzes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.quizzes_id_seq', 1, false);


--
-- Name: review_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.review_logs_id_seq', 1, false);


--
-- Name: user_flashcards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.user_flashcards_id_seq', 1, false);


--
-- Name: word_lists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.word_lists_id_seq', 1, false);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: categories categories_slug_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_slug_key UNIQUE (slug);


--
-- Name: user_flashcards fk_user_flashcards_unique; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.user_flashcards
    ADD CONSTRAINT fk_user_flashcards_unique UNIQUE (user_id, card_id, direction);


--
-- Name: flashcards flashcards_list_id_base_word_translation_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.flashcards
    ADD CONSTRAINT flashcards_list_id_base_word_translation_key UNIQUE (list_id, base_word, translation);


--
-- Name: flashcards flashcards_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.flashcards
    ADD CONSTRAINT flashcards_pkey PRIMARY KEY (id);


--
-- Name: quiz_attempts quiz_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quiz_attempts
    ADD CONSTRAINT quiz_attempts_pkey PRIMARY KEY (id);


--
-- Name: quiz_attempts quiz_attempts_quiz_id_card_id_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quiz_attempts
    ADD CONSTRAINT quiz_attempts_quiz_id_card_id_key UNIQUE (quiz_id, card_id);


--
-- Name: quizzes quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT quizzes_pkey PRIMARY KEY (id);


--
-- Name: review_logs review_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.review_logs
    ADD CONSTRAINT review_logs_pkey PRIMARY KEY (id);


--
-- Name: user_flashcards user_flashcards_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.user_flashcards
    ADD CONSTRAINT user_flashcards_pkey PRIMARY KEY (id);


--
-- Name: user_flashcards user_flashcards_user_id_card_id_direction_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.user_flashcards
    ADD CONSTRAINT user_flashcards_user_id_card_id_direction_key UNIQUE (user_id, card_id, direction);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: word_lists word_lists_name_language_from_language_to_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.word_lists
    ADD CONSTRAINT word_lists_name_language_from_language_to_key UNIQUE (name, language_from, language_to);


--
-- Name: word_lists word_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.word_lists
    ADD CONSTRAINT word_lists_pkey PRIMARY KEY (id);


--
-- Name: idx_flashcards_base_word; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_flashcards_base_word ON public.flashcards USING gin (to_tsvector('simple'::regconfig, base_word));


--
-- Name: idx_flashcards_list_category; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_flashcards_list_category ON public.flashcards USING btree (list_id, category_id);


--
-- Name: idx_quiz_attempts_quiz; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_quiz_attempts_quiz ON public.quiz_attempts USING btree (quiz_id);


--
-- Name: idx_review_logs_user_card; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_review_logs_user_card ON public.review_logs USING btree (user_id, card_id, reviewed_at DESC);


--
-- Name: idx_user_flashcards_due; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_user_flashcards_due ON public.user_flashcards USING btree (user_id, next_review_at) WHERE (status = ANY (ARRAY[1, 2]));


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: categories categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: flashcards flashcards_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.flashcards
    ADD CONSTRAINT flashcards_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: flashcards flashcards_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.flashcards
    ADD CONSTRAINT flashcards_list_id_fkey FOREIGN KEY (list_id) REFERENCES public.word_lists(id) ON DELETE CASCADE;


--
-- Name: quiz_attempts quiz_attempts_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quiz_attempts
    ADD CONSTRAINT quiz_attempts_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.flashcards(id) ON DELETE CASCADE;


--
-- Name: quiz_attempts quiz_attempts_quiz_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quiz_attempts
    ADD CONSTRAINT quiz_attempts_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id) ON DELETE CASCADE;


--
-- Name: quiz_attempts quiz_attempts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quiz_attempts
    ADD CONSTRAINT quiz_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: quizzes quizzes_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT quizzes_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: quizzes quizzes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT quizzes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: review_logs review_logs_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.review_logs
    ADD CONSTRAINT review_logs_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.flashcards(id) ON DELETE CASCADE;


--
-- Name: review_logs review_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.review_logs
    ADD CONSTRAINT review_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_flashcards user_flashcards_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.user_flashcards
    ADD CONSTRAINT user_flashcards_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.flashcards(id) ON DELETE CASCADE;


--
-- Name: user_flashcards user_flashcards_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.user_flashcards
    ADD CONSTRAINT user_flashcards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: DATABASE myapp; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE myapp TO appuser;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO appuser;


--
-- Name: FUNCTION citextin(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextin(cstring) TO appuser;


--
-- Name: FUNCTION citextout(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextout(public.citext) TO appuser;


--
-- Name: FUNCTION citextrecv(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextrecv(internal) TO appuser;


--
-- Name: FUNCTION citextsend(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextsend(public.citext) TO appuser;


--
-- Name: TYPE citext; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.citext TO appuser;


--
-- Name: FUNCTION citext(boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(boolean) TO appuser;


--
-- Name: FUNCTION citext(character); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(character) TO appuser;


--
-- Name: FUNCTION citext(inet); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(inet) TO appuser;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea) TO appuser;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO appuser;


--
-- Name: FUNCTION citext_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_cmp(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_eq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_eq(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ge(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_gt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_hash(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash(public.citext) TO appuser;


--
-- Name: FUNCTION citext_hash_extended(public.citext, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash_extended(public.citext, bigint) TO appuser;


--
-- Name: FUNCTION citext_larger(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_larger(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_le(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_lt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_ne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ne(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_cmp(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_ge(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_gt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_le(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_lt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_smaller(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_smaller(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crypt(text, text) TO appuser;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dearmor(text) TO appuser;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(bytea, text) TO appuser;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(text, text) TO appuser;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO appuser;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_uuid() TO appuser;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text) TO appuser;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO appuser;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO appuser;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION regexp_match(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_match(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_matches(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_matches(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text, text) TO appuser;


--
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION replace(public.citext, public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.replace(public.citext, public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION split_part(public.citext, public.citext, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.split_part(public.citext, public.citext, integer) TO appuser;


--
-- Name: FUNCTION strpos(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strpos(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticnlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticnlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticregexeq(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticregexeq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticregexne(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticregexne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION translate(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.translate(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION max(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.max(public.citext) TO appuser;


--
-- Name: FUNCTION min(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.min(public.citext) TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TYPES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO appuser;


--
-- PostgreSQL database dump complete
--

\unrestrict MChfUZZ0x5iQOpXgOA1xMIKrSh5XbNYJntPM4icsi1SivJXWTLgVUeYHijqNVI1

